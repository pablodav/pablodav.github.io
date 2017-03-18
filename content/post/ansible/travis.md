---
date: 2017-03-18T20:06:24-03:00
title: travis
type: index
menu:
  main:
    parent: Material
    identifier: ansible_travis
    weight: 0
draft: true
---

Automated Import to Travis
--------------------------

http://docs.ansible.com/ansible/galaxy.html#travis-integrations


```bash

$ ansible-galaxy login


We need your Github login to identify you.
This information will not be sent to Galaxy, only to api.github.com.
The password will not be displayed.

Use --github-token if you do not want to enter your password.

Github Username: pablodav
Password for pablodav: 
Succesfully logged into Galaxy as pablodav

$ ansible-galaxy setup travis pablodav ansible_burp2_server YOURTRAVISTOKENHERE
Added integration for travis pablodav/ansible_burp2_server
```
