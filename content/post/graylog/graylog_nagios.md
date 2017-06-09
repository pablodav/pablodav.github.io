---
categories:
- graylog
- nagios
- monitoring
date: 2017-06-09T14:58:34-03:00
menu:
  main:
    parent: Material
    weight: 0
title: Graylog2 - 4 Nagios Services checks
type: index
---

After you have all the previous setup done, please don't forget to add additional checks to ensure graylog is always running, examples with nagios: 

```
# file: graylog_servers_services.cfg

define service {
    host_name               GRAYLOG_HOST
    service_description     logstash_service_running
    check_command           check_service_nrpe!logstash
    use                     generic-service
    notes                   Some important notes
}

define service {
    host_name               GRAYLOG_HOST
    service_description     graylog-server_service_running
    check_command           check_service_nrpe!graylog-server
    use                     generic-service
    notes                   Some important notes
}

```

Roles used on Nagios server to setup these commands: 

https://github.com/CoffeeITWorks/ansible_nagios4_server_plugins

https://github.com/pablodav/ansible_nagios_common_nrpe

https://github.com/search?utf8=%E2%9C%93&q=org%3ACoffeeITWorks+nagios&type=
