---
date: 2017-03-14T7:31:51-03:00
title: Graylog2 - 1 - with ansible
type: index
menu:
  main:
    parent: Material
    identifier: graylog2-ansible
    weight: 0
---

Introduction
------------

[Graylog2](https://www.graylog.org/) is an excelent log management and server, with many features and nice GUI interface 
to use and configure streams, inputs, alerts, searchs, dashboards, etc.

This document will explain how setup [graylog2 using ansible](https://github.com/Graylog2/graylog-ansible-role).

This document will be base for future documents that explain how to add more
customizations with other roles:

* [Upgrading practice example.](#upgrading-graylog)
* Input from [logstash](https://github.com/mrlesmithjr/ansible-logstash). Done at: [Graylog_ansible_logstash_input]({{< relref "logstash_input.md" >}})
* Receive [azure alarms](https://docs.microsoft.com/en-us/azure/monitoring-and-diagnostics/insights-webhooks-alerts). Done at: [Graylog_ansible_logstash_input]({{< relref "logstash_input.md" >}})
* Configure commands to send alarms to [nagios with nsca](https://github.com/CoffeeITWorks/ansible_nagios_graylog2_nsca). Done: [Graylog_ansible_logstash_nagios_nsca]({{< relref "graylog_logstash_nagios_nsca.md" >}})
* [Configure nagios](https://github.com/CoffeeITWorks/ansible_nagios_graylog2_nsca_config_nagios) to receive them. Done: [Graylog_ansible_logstash_nagios_nsca]({{< relref "graylog_logstash_nagios_nsca.md" >}})
* Explain more about graylog with more links to graylog documentation. **TODO**

Requirements
------------

You need to know some basics from [ansible](http://docs.ansible.com/ansible/quickstart.html), and ofcourse [install ansible](http://docs.ansible.com/ansible/intro_installation.html)

Don't be scared about it, ansible is the most simple IT automation tool and you will get benefits learing this to manage
any other thing on your servers. Check also [how ansible works](https://www.ansible.com/how-ansible-works), and [get-started](https://www.ansible.com/get-started)

Installing roles
----------------

Before starting to define the usage of our roles, we need them installed on our 
**[ansible-control-machine](http://docs.ansible.com/ansible/intro_installation.html#control-machine-requirements)**.
 As we will use this machine to actively connect and push configurations to our **graylog2 server**. 


We will use `requirements.yml` file to make the installation of roles faster.

Add/create your `requirements.yml` file: 

```yaml

# graylog2 

- src: graylog2.graylog
  version: 2.3.0

# graylog2 dependency

- src: lesmyrmidons.mongodb
  version: v1.2.8

- src: geerlingguy.java
  version: master

# 0.2 is required version to use elasticsearch 2.x
- src: elastic.elasticsearch
  version: "5.5.1"

- src: jdauphant.nginx
  version: master
```

As written in the `requirements.yml` file, **elasticsearch** must be version **2**. So we need to use the branch for 0.2 of the role.
 
### Install from `requirements.yml`

    sudo ansible-galaxy install -r requirements.yml


{{< note title="Note" >}}
The **graylog2 server** can be also your **ansible-control-machine** if you don't have other, 
using **localhost** as node in your **inventory** as shown below. 
{{< /note >}}

{{< warning title="Elasticsearch and java version matters" >}}
You must ensure to be using elasticsearch 2, and java from openjdk-8, we will cover these
steps below, but this note will help you to know and remmember that.
{{< /warning >}}


Preparing the inventory
-----------------------

We will setup a group called **graylog2_servers** with the hosts added to it. 

You need to create/edit your [inventory](http://docs.ansible.com/ansible/intro_inventory.html) to tell ansible which server is on **graylog2_servers** group. 

We will create a folder called `inventory` and a file called `production` on it. 

file: `inventory/production`

content:

```ini
[location1]
server1     ansible_host=192.168.1.50

[graylog2_servers]
server1
```

In this example I have added `server1` to groups **location1**  and **graylog2_servers**.
Note also I have added `ansible_host` variable with the IP address of `server1`, so ansible will use automatically this 
to connect to the host.

other generic example: [example1/inventory/test](https://github.com/CoffeeITWorks/ansible-generic-help/blob/master/example1/inventory/test)

Preparing the playbook to run the roles
---------------------------------------

We will define a playbook to include our [roles](http://docs.ansible.com/ansible/playbooks_roles.html#roles). 

We will prepare a file called `roles.graylog2.yml` with this definition: 

```yaml

---
# This --- defines that this yaml file will have 2 spaces for indentation.


# In case you use Ubuntu trusty we will add ppa for java-jdk8
# as noticed on warning above we need to take care of it. 

- name: Add java-jdk-8 ppa for Ubuntu trusty
  hosts: graylog2_servers
  become: yes

  # You can specify a proxy_env var with your proxy settings here
  # check example: https://github.com/CoffeeITWorks/ansible-generic-help/blob/master/example1/group_vars/all/vars#L14
  #environment: "{{ proxy_env }}"

  tasks:
    - name: installing repo for Java 8 in Ubuntu 14.04
      apt_repository: repo='ppa:openjdk-r/ppa'
      when: ansible_distribution_release == 'trusty'

# Now we will apply all roles to our graylog2_servers:

- name: Apply roles for graylog2 servers
  hosts: graylog2_servers
  become: yes

  # You can specify a proxy_env var with your proxy settings here
  # check example: https://github.com/CoffeeITWorks/ansible-generic-help/blob/master/example1/group_vars/all/vars#L14
  #environment: "{{ proxy_env }}"

  roles:

    - role: lesmyrmidons.mongodb
      tags:
        - role::mongodb
        - graylog2_servers

    # This step is important as described in waring above
    - role: geerlingguy.java
      when: ansible_distribution_release == 'trusty'
      java_packages:
        - openjdk-8-jdk
      tags:
        - role::elasticsearch
        - graylog2_servers

    # This step is important as described in waring above
    - role: geerlingguy.java
      when: ansible_os_family == "RedHat" and ansible_lsb.major_release|int >= 7
      java_packages:
        - java-1.8-openjdk
      tags:
        - role::elasticsearch
        - graylog2_servers

    # ensure you have installed 0.2 branch for elasticsearch 2.x
    - role: elastic.elasticsearch
      tags:
        - role::elasticsearch
        - graylog2_servers

    - role: jdauphant.nginx
      tags:
        - role::nginx
        - graylog2_servers

    # Here we will install graylog
    - role: graylog2.graylog
      tags:
        - role::graylog
        - graylog2_servers

```

Preparing the variables
-----------------------

We have an **inventory** and a **playbook** to call the roles, but we must customize the [variables](http://docs.ansible.com/ansible/playbooks_variables.html#variable-precedence-where-should-i-put-a-variable) before running
 the playbook.

Here we will organize the variables files into the `group_vars` directory:

    mkdir -p group_vars/graylog2_servers

Then add a file to have organized the variables for **elasticsearch**.

`group_vars/graylog2_servers/elasticsearch2_vars` file:

In this file we will define **es cluster**, bind address, version, memory, etc.

```yaml

---
# https://github.com/Graylog2/graylog-ansible-role

es_instance_name: 'graylog'
es_scripts: False
es_templates: False
es_version_lock: False
es_heap_size: 1g

# Graylog2.3 supports elasticsearch 5, so must install elasticsearch 5.x
es_major_version: "5.x"
es_version: "5.5.1"

graylog_version: '2.3'
# pin version is broken in: 2.3.0 of ansible_graylog2_role
# hope will be fixed on future, you will need to delete /etc/apt/preferences.d/elasticsearch
# see https://github.com/Graylog2/graylog-ansible-role/commit/4e24252bd71e4cc2bb53df0a069c617138dc09cd#commitcomment-25811249
graylog_es_debian_pin_version: '5.*'

es_config: {
  node.name: "graylog",
  cluster.name: "graylog",
  http.port: 9200,
  transport.tcp.port: 9300,
  network.host: 0.0.0.0,
  node.data: true,
  node.master: true,
}


# Ensure to add this option if not added elastic.elasticsearch will install openjdk-7 that will break graylog2
es_java_install:               False

```

Then add a file to have organized the variables for **graylog role**. 

`group_vars/graylog2_servers/graylog2_vars` file:

```yaml

---

# Disable autoinstall of elasticsearch, java, mongodb, etc, as we will use our own playbook to call the roles:
# And ensure correct java version is installed in this way
graylog_install_elasticsearch: False
graylog_install_mongodb:       False
graylog_install_nginx:         False
graylog_install_java:          False

# Basic server settings (seems that this should go per host)
graylog_is_master:          'True'

# generate with: pwgen -s 96 1
graylog_password_secret:    'putyourhashhere'

# generate with: echo -n yourpassword | shasum -a 256
graylog_root_password_sha2: 'putyourhashhere'

# Elasticsearch message retention
# Specify your retention here
graylog_elasticsearch_max_docs_per_index:    20000000
graylog_elasticsearch_max_number_of_indices: 20
graylog_elasticsearch_shards:                4
graylog_elasticsearch_replicas:              0

graylog_rest_listen_uri:  'http://0.0.0.0:9000/api/'
graylog_web_listen_uri:   'http://0.0.0.0:9000/'

nginx_sites:

  graylog:
    - listen 80
    - server_name graylog
    - location / {
      proxy_pass http://localhost:9000/;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_pass_request_headers on;
      proxy_connect_timeout 150;
      proxy_send_timeout 100;
      proxy_read_timeout 100;
      proxy_buffers 4 32k;
      client_max_body_size 8m;
      client_body_buffer_size 128k; }

# Setup per host on host_vars:
graylog_web_endpoint_uri: 'http://{{ ansible_host }}:9000/api/'

# Optionally for Ubuntu 14.04 you can use:
mongodb_repository: "deb [ arch=amd64 ] http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.4 multiverse"


```

Not all the variables are required, but I prefer to be explicit on these settings. The documentation of these vars are 
on the readme of each role, also the defaults used are on the `defaults/main.yml file` of each role (we are overriding the
defaults when assigning the vars on `group_vars`). 

See [playbook_variables](http://docs.ansible.com/ansible/playbooks_variables.html#variable-precedence-where-should-i-put-a-variable) 
for more information

Review what's done until now
----------------------------

We have created:

* `requirements.yml` file
* `inventory/production` file
* `roles.graylog2.yml` file
* `group_vars/graylog2_servers` dir with `elasticsearch_vars` and `graylog2_vars` files

So, our tree looks: 

```bash
├── requirements.yml
├── group_vars
│   ├── graylog2_servers
│   │   ├── graylog2_vars
│   │   ├── elasticsearch_vars
├── inventory
│   ├── production
├── roles.graylog2.yml

```

With this structure we have all required to call our roles with correct parameters. 
As seen on the roles.graylog2.yml, we have associated the roles to run to **graylog2_servers** group.

Run the playbook
----------------

We will execute here: 

    ansible-playbook -i inventory roles.graylog2.yml --limit graylog2_servers -u user -k -K --become

To understand some of the parameters used here:

```
-l SUBSET, --limit=SUBSET
                    further limit selected hosts to an additional pattern
-i PATH, --inventory=PATH
                    The PATH to the inventory hosts file, which defaults to /etc/ansible/hosts. 
-k, --ask-pass
                    Prompt for the SSH password instead of assuming key-based authentication with ssh-agent. 
-K, --ask-sudo-pass
                    Prompt for the password to use for playbook plays that request sudo access, if any. 
-b, --become
                    run operations with become (does not imply password prompting) 
-u USERNAME, --remote-user=USERNAME
                    Use this remote user name on playbook steps that do not indicate a user name to run as. 
```

As seen on the command, we use `-i inventory` directory instead of the file, you can change it to point to the file directly.

You can also check [ansible-vault](http://docs.ansible.com/ansible/playbooks_vault.html) to save password. 

You can also check variables to use in `group_vars/all` or some other group using [inventory_parameters](http://docs.ansible.com/ansible/intro_inventory.html#list-of-behavioral-inventory-parameters)

Ansible connections are done by default with ssh, you can change them using `inventory_parameters` and also disable [host-key-checking](http://docs.ansible.com/ansible/intro_getting_started.html#host-key-checking). 
Create ansible.cfg file on same dir where you run `ansible-playbook` command and it will read that parameters. 

Upgrading Graylog
-----------------

As ansible role is updated every time graylog is update too (check [graylog_version](https://github.com/Graylog2/graylog-ansible-role/blob/master/defaults/main.yml#L8)). 
You only need to update the role installed, ex: 

    sudo rm -rf /etc/ansible/roles/graylog2.graylog
    sudo ansible-galaxy install -r requirements.yml 

Then [run the playbook](#run-the-playbook) again.

This will update your graylog repository, for example in my output I have: 

```bash
TASK [graylog2.graylog : Graylog repository package should be downloaded] ******
changed: [server1] => {"changed": true, "checksum_dest": null, "checksum_src": "ddc77cda9473f6556844c19d68c2c8de05d9dedc", "dest
": "/tmp/graylog_repository.deb", "gid": 0, "group": "root", "md5sum": "df0ded30076548179772cd23bfff869f", "mode": "0644", "msg":
"OK (2056 bytes)", "owner": "root", "size": 2056, "src": "/tmp/tmpjrGQFl", "state": "file", "uid": 0, "url": "https://packages.gra
ylog2.org/repo/packages/graylog-2.2-repository_latest.deb"}
```

Then just upgrade on your server: 

    sudo apt-get upgrade

Or with yum: 

    sudo yum update

If for some reason the role is not updated, you can add to your `group_vars/graylog2_servers/graylog2_vars`, ex:

    graylog_version: 2.2
    
It should make same effect but without the fixes and improvements added to the role. 
**It's recommended to update the role**, and also **check the release notes** of both: role and graylog2.

Ensure you are not upgrading elasticsearch to 5.x, to not break graylog. (should not do that if you did all steps in this page)
