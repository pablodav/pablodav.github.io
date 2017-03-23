---
categories:
- "graylog"
- "logstash"
- "ansible"
- "logging"
date: 2017-03-22T14:37:48-03:00
menu:
  main:
    parent: Material
    weight: 0
title: Graylog2 - 2 - logstash input http
type: index
---

Introduction
------------

* Configure [**GELF**](http://docs.graylog.org/en/latest/pages/gelf.html) input in graylog. 
* Prepare **logstash** to input data from any [http](https://www.elastic.co/blog/introducing-logstash-input-http-plugin) post.
* Send data to **GELF** input in graylog using [plugins_output_gelf](https://www.elastic.co/guide/en/logstash/current/plugins-outputs-gelf.html).
 
![graylog_gelf_logstash](/img/graylog_gelf_logstash.png)

Requirements Ansible
--------------------

As explained in [Generic-help installing roles](https://github.com/CoffeeITWorks/ansible-generic-help#installing-roles). 
And at [Graylog_ansible_installing_roles]({{< relref "graylog_ansible.md#installing-roles" >}})

We will use `requirements.yml` to add this: 

```
- src: mrlesmithjr.logstash
  name: ansible-logstash
  version: master
```

Then install with `ansible-galaxy install -r requirements.yml`

It will install the role with name `ansible-logstash`, we will use that name in our playbook.

Requirements Graylog2
---------------------

Here we need to add an input to receive the messages from **logstash**. 

Go to System -> Inputs

![System_inputs](/img/graylog_system_input.png)

* Select **GELF UDP INPUT**.  
* We will use port 12201
* save 
* Start the input

After done, you could see something like: 

![graylog_input_gelf_udp](/img/graylog_input_gelf_udp.png)

{{< warning title="Port below 1024 will not work" >}}
Graylog2 is running as normal user, linux will not allow port below 1024
{{< /warning >}}

Ansible Inventory
-----------------

We will use same inventory as created at: at [Graylog_ansible_inventory]({{< relref "graylog_ansible.md#preparing-the-inventory" >}})


Preparing the playbook to run the roles
---------------------------------------

Here we will add to `roles.graylog2.yml` as examplained at: [Graylog_ansible_playbook]({{< relref "graylog_ansible.md#preparing-the-playbook-to-run-the-roles" >}})

```

- name: Apply logstash for graylog2 servers
  hosts: graylog2_servers
  become: yes

  roles:

    - role: ansible-logstash
      tags:
        - role::logstash
        - graylog2_servers

```

Preparing the variables
-----------------------

We will create new file `group_vars/graylog2_servers/logstash_vars`

The folder was created during the preparatives at: [Graylog_ansible_variables]({{< relref "graylog_ansible.md#preparing-the-variables" >}})

Variables:

```ini

# logstash role:

pri_domain_name: 'example.com'
config_logstash: True
logstash_install_java: false

# These are the files that will be used and will be created in `/etc/logstash/conf.d/`
logstash_base_configs:
  - '000_inputs'
  - '001_filters'
  - '999_outputs'

# Plugins required by us
logstash_plugins:
  - 'logstash-output-nagios_nsca'
  - 'logstash-output-gelf'

# see https://github.com/mrlesmithjr/ansible-logstash
logstash_base_file_inputs: []


# We don't need it really, but will add anyway
logstash_base_inputs:  #define inputs below to configure
  - prot: 'tcp'
    port: '10514'  #gets around port < 1024 (Note...Configure clients to send to 10514 instead of default 514)
    type: 'syslog'

# Here we are creating one input, in this case we will add a tag to make it easier to filter
# example is with azure tag, but can be any other.
logstash_custom_inputs:
  - input: 'http'
    lines:
      - 'port => "51202"'
      - 'type => "http"'
      - 'tags => "azure"'

# Here we will use the tag to create a filter and apply json module to 
# transform the message into json format
logstash_custom_filters:
  - lines:
      - 'if "azure" in [tags] {'
      - '  json {'
      - '    source => "message"'
      - '  }'
      - '}'

# As we will not use any default output, we will leave it as empty list []
logstash_base_outputs: []

# Here we will tell ansible role to configure the output to our GELF UDP input.
logstash_custom_outputs:

  - output: 'gelf'
    lines:
      - 'host => "localhost"'
      - 'port => "12201"'

```

All these vars will tell what we exactly want from ansible role for logstash. 

Run the playbook
----------------

use same steps as described in: [Graylog_ansible_run]({{< relref "graylog_ansible.md#run-the-playbook" >}})

Or run only logstash role calling with tag: 

    ansible-playbook -i inventory roles.graylog2.yml --limit graylog2_servers -u user -k -K --become --tags role::logstash 
    
Upgrading logstash
------------------

Just use normal package upgrade from your distribution. 

Receive Azure alarms
--------------------

Just setup your [azure alarms](https://docs.microsoft.com/en-us/azure/monitoring-and-diagnostics/insights-webhooks-alerts), 
to your public IP and HTTP Port: `51201` as done at [Preparing the variables](#preparing-the-variables)

