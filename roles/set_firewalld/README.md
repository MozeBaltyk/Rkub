Role Name
=========

Role to set firewalld's inbound rules and zones
 
Documentations
------------

Inspired by: https://www.clockworknet.com/blog/2020/03/17/managing-firewalld-with-ansible-part-2/

Role Variables
--------------

Variable should respect this structure: 

```yml
# set default zone
firewalld_default_zone: custom

# add/change inbound rules
firewalld_rules:
  inbound:
    - name: your-service-name
      zone: public
      ports:
        - { port:         443, protocol: tcp }
        - { port:        6443, protocol: tcp }
        - { port:        8472, protocol: udp }
        - { port:       10250, protocol: tcp }
        - { port: 30000-32767, protocol: tcp }

# add/change zones
firewalld_zones:
  - name: development
    sources:
      - 192.168.10.0/24
  - name: testing
    target: ACCEPT
    interfaces:
      - eth0
    sources:
      - 192.168.20.0/24
      - 192.168.30.0/24

# remove a service completely
firewalld_remove:
  inbound:
    - name: app1
      zone: public
      erase: true        #when erase false, remove service only from zone.
```

Example Playbook
----------------

1. From playbooks:

```yml
roles:
- { role: 'mozebaltyk.rkub.set_firewalld', tags: 'firewalld' }

vars:
  firewalld_rules:
    inbound:
      - name: nodeports
        zone: public
        ports:
          - { port:         443, protocol: tcp }
          - { port: 30000-32767, protocol: tcp }
```

2. From another role:   

```yml 
- import_role:
    name: "mozebaltyk.rkub.set_firewalld"
```

In your playbook:   
```yml
  roles:
  - { role: 'mozebaltyk.rkub.set_firewalld', tags: 'firewalld', firewalld_rules: "{{ master_firewalld_rules }}" }
```

Then set your variables in ./vars/main.yml:
```yml
master_firewalld_rules:
  inbound:
    - name: rke2-server
      zone: public
      ports:
        - { port:         443, protocol: tcp }
        - { port:        6443, protocol: tcp }
        - { port:        8472, protocol: udp }
        - { port:       10250, protocol: tcp }
```


License
-------

Apache-2.0

Author Information
------------------

morze.baltyk@proton.me