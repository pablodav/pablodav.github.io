---
date: 2017-03-18T20:06:24-03:00
title: Ansible win Update and Security patching
type: index
menu:
  main:
    parent: Ansible_Win
    identifier: ansible_win_security
    weight: 0
---

Updating windows with ansible
=============================

Patching windows is a very time consuming task, but working with ansible you could
reduce this time significantly.

Here I will share some playbooks that will help on these tasks.

First of all, you must ensure to keep all your windows servers updated:

```yaml
---
# file: windows-updates-all.yml

- hosts: all
  any_errors_fatal: false
  serial:
   - 1
   - 5%
   - 25%
  max_fail_percentage: 10%
  vars:
    win_updates_categories:
      - CriticalUpdates
      - SecurityUpdates
  tasks:
  # Check if there are missing updates
  - name: Check for missing updates.
    win_updates:
      state: searched
      category_names: "{{ win_updates_categories }}"
    register: update_count
    ignore_errors: yes

  - name: Reboot if needed
    win_shell: Restart-Computer -Force
    when: update_count.reboot_required
    ignore_errors: yes

  - name: Install missing updates.
    win_updates:
      category_names: "{{ win_updates_categories }}"
    register: update_result

  - name: Reboot if needed
    win_shell: Restart-Computer -Force
    when: update_result.reboot_required
    ignore_errors: yes

```

Audit windows patches with ansible
----------------------------------

Then you need to test if the important patch is installed.

We will use in this case the information about patches for ramsomeware, normally in windows this 
information is obtained in this way:

```powershell

# Windows7 win2008 ServicePack2:
get-hotfix -id "kb4012598"

# win2008R2 hotfix RAMSOMWARE MARCH 2017:
get-hotfix -id "KB4012212"

# win2012R2 hotfix RAMSOMEWARE MARCH 2017:
get-hotfix -id "KB4012213"

# Windows2012 hotfix RAMSOMEWARE MARCH 2017:
get-hotfix -id  "KB4012214"

# win2003 hotifx RAMWOMEWARE MARCH 2017:
# KB4012598
# Windows 2003 doesn't provide get-hotfix and can't be managed with winrm.
```

Then we will use this playbook to audit the servers:

```yaml
- name: verify windows patches
  hosts: all
  any_errors_fatal: false
  serial:
   - 100%
  max_fail_percentage: 10%
  tasks:
  # Verify windows updates
  - name: verify windows patch windows 2008 R2
    win_shell: get-hotfix {{ item.id }}
    when: "'Windows Server 2008 R2' in ansible_os_name"
    with_items:
      - id: KB4012212
        description: hotfix RAMSOMWARE MARCH 2017
    changed_when: false

  # Verify windows updates
  - name: verify windows patch windows 2008 Standard
    win_shell: get-hotfix {{ item.id }}
    when: "'Windows Server 2008 Standard' in ansible_os_name"
    with_items:
      - id: kb4012598
        description: hotfix RAMSOMWARE MARCH 2017
    changed_when: false

  # Verify windows updates
  - name: verify windows patch windows 2012 R2
    win_shell: get-hotfix {{ item.id }}
    when: "'Windows Server 2012 R2' in ansible_os_name"
    with_items:
      - id: KB4012213
        description: hotfix RAMSOMWARE MARCH 2017
    changed_when: false

  # Verify windows updates
  - name: verify windows patch windows 2012 Standard
    win_shell: get-hotfix {{ item.id }}
    when: "'Windows Server 2012 Standard' in ansible_os_name"
    with_items:
      - id: KB4012214
        description: hotfix RAMSOMWARE MARCH 2017
    changed_when: false

```

Workaround some patches
-----------------------

In some cases, patching windows is not enough or sometimes windows has some
undesired errors that doesn't allow to install the KB.

For these cases we can workaround over windows, we can do this for example
to a group or list of hosts.

I will add an example to workaround ramsomeware:

```yaml
# https://technet.microsoft.com/en-us/library/security/ms17-010.aspx

- name: Apply ramsomeware patch disable smb v1
  hosts: group1,server,server2
  tasks:
  - name: apply ramsomeware patch disable smb v1
    win_regedit: key={{ item.key }} value={{item.value}} data={{ item.data}} datatype={{ item.datatype }} state=present
    with_items:
      - key: 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters'
        value: 'SMB1'
        datatype: 'dword'
        data: '0'
    register: apply_patch_ramsomeware

  - name: Reboot if needed
    win_shell: Restart-Computer -Force
    when: apply_patch_ramsomeware.changed
    ignore_errors: yes

```
