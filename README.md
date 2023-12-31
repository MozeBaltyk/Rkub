<h1 style="text-align: center;"><code> Ansible Collection - Rkub  </code></h1>

Ansible Collection to deploy a rancher RKE2 cluster in airgap mode.

[![Releases](https://img.shields.io/github/release/MozeBaltyk/rkub)](https://github.com/MozeBaltyk/rkub/releases)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-green.svg)](https://opensource.org/licenses/Apache-2.0/)

## Description

This Project is mainly inspired from [Clemenko/rke_airgap_install](https://github.com/clemenko/rke_airgap_install/blob/main/air_gap_all_the_things.sh). 
I tried it and the idea pleased me but I had small frustrations about the Shell scripting limitations. So I decided to rewrite it in Ansible.  

With Ansible:
- Idempotency: can be relaunch multiple time. 
- User agnostic: can be launch by any user (with sudo rights). 
- OS agnositc: can be launch on any Linux systems (at least for the package build, for the install depend on your participation to this project 😸)

Add-on from my part:
- Some part which were manual in Clemenko procedure are automated with Ansible (like the download)
- Some flexibility about path (possible to export or mount NFS in choosen place)
- Arkade to install utilities binaries
- Admin user (by default kuberoot) on first controler node with all necessary tools
- Nerdctl (as complement of containerd) 
- Firewalld settings if firewalld is activated
- Uninstall playbook to cleanup (and maybe reinstall)

## Prerequisites

* Linux Host as a package builder (can be a VM or your WSL)

* An Ansible Controler, can be the same host for ansible and for building package, at your convenience...

* minimum of 2 hosts RHEL-like for the cluster RKE2.

## Getting started

1. Clone this project on local machine which have an internet access and complete directory inside ./plugins/inventory/hosts.yml. 


2. Build your package by running (works on Debian-like and Redhat-like):  
```sh 
ansible-playbook playbooks/tasks/build.yml   # Args below are not mandatory
-e dir_build="$HOME/rkub"                    # Directory where to upload everything (count 30G)
-e package_name="rke2_rancher_longhorn.zst"  # Name of the package, by default rke2_rancher_longhorn.zst
-u admin -Kk                                 # Other Ansible Arguments (like -vvv)
```

Count 30G of free space in your build directory (17G for download + 7G for the zst package).

3. Push your package to first controler:  
```sh
ansible-playbook playbooks/tasks/download.yml      # Args below are not mandatory
-e package_path=/home/me/rke2_rancher_longhorn.zst # Will be prompt if not given in the command
-e dir_target=/opt                                 # Directory where to sync and unarchive (by default /opt, count 50G available) 
-u admin -Kk                                       # Other Ansible Arguments (like -vvv)   
```

4. Start installation: 
```sh
ansible-playbook playbooks/tasks/install.yml       # Args below are not mandatory
-e package_name="rke2_rancher_longhorn.zst"        # Name of the package, by default rke2_rancher_longhorn.zst
-e dir_target=/opt                                 # Dir on first master which is going to be export (by default /opt, count 50G available) 
-e dir_mount=/mnt/rkub                             # NFS mount point (on first master, it will be a symlink to "dir_target")
-u admin -Kk                                       # Other Ansible Arguments (like -vvv)
```

## Roadmap
milestones:
- To deploy some stuff
- HA masters with kubevip
- more install customization and options
- Github Workflows / Release
- To add bootstrap with ArgoCD

Improvment:
- Add a option to chooce by url mode or airgap mode

# Special thanks to 📢

* Clemenko, for the idea [Clemenko/rke_airgap_install](https://github.com/clemenko/rke_airgap_install/blob/main/air_gap_all_the_things.sh).
* Alex Ellis, for its [Arkade project](https://github.com/alexellis/arkade). I cannot live without anymore.

## Github sources 

[Clemenko/rke_airgap_install](https://github.com/clemenko/rke_airgap_install/blob/main/air_gap_all_the_things.sh)   

what I like: 
  - Can package the all stuff
  - Airgap
  - Local registry shared in NFS

What is missing: 
  - Ansible - to make it idempotent and executable from a single point.
  - Upload package to target.

[rancherfederal/RKE2-ansible](https://github.com/rancherfederal/rke2-ansible)

what I like: 
  - Ansible 
  - HA controlers  

What is missing:
  - proper Airgap

[lablabs/ansible-role-rke2](https://github.com/lablabs/ansible-role-rke2)     
what I like: 
  - Ansible   

What is missing:
  - no packaging for airgap.
  - no script to transfert

[rancher/RKE2](https://github.com/rancher/rke2)

## Authors
morze.baltyk@proton.me

## Project status
Still on developement
