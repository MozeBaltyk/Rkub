Role Name
=========

Role to install on all nodes nerdctl

Requirements
------------

*Example below show that the roles have two flavors and different requirements in functions of what you want*

if idm set to true:
- Access to a IDM server if you want to create users account.
- Credentials access to connect to IDM

if idm set to false:
- create local account on Linux servers

Role Variables
--------------

| **VarName**        | **Type** | **Content**               | **Mandatory** |
|--------------------|----------|---------------------------|:-------------:|
| idm                | boolean  | true / false              | x             |
| svc_account        | string   | Service Account           | x             |
| svc_account_passwd | string   | pwd (can be omited)       |               |
| svc_group          | string   | Group                     |               |
| svc_owner          | string   | Owner of the account      | if idm true   |
| list_svc_account   | list     | Users which goes in group | if idm true   |
| idm_server         | string   | Service Account PWD       | if idm true   |
| idm_pwd            | string   | sudo group                | if idm true   |

**Mandatory** is the minimum variables that need to be set to make the role work
*the variables not mandatory either have a default value defined or can be omited*

Dependencies
------------

Dependencies with some others roles (if there is some).

Example Playbook
----------------
Give some example about how to use or implement your Roles


```yml
- name: Trigger Role Example in a Playbooks
  hosts: RANDOM_GROUP_DEFINED_IN_YOUR_INVENTORY
  remote_user: ansible
  become: true

  roles:
  - { role: 'example',   tags: 'example'  }
```

```yml
# Example for one user
- import_role:
    name: "example"
  vars:
    svc_account:         "{{ tomcat_svc_account }}"
    svc_group:           "{{ tomcat_svc_group   }}"
```

License
-------

Apache-2.0

Author Information
------------------

morze.baltyk@proton.me