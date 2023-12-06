<h1 style="text-align: center;"><code> Ansible Collection - Rkub  </code></h1>

Ansible Collection to deploy a rancher RKE2 cluster in airgap mode.

[![Releases](https://img.shields.io/github/release/MozeBaltyk/rkub)](https://github.com/MozeBaltyk/rkub/releases)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-green.svg)](https://opensource.org/licenses/Apache-2.0/)

## Description

This Project is mainly inspired from [Clemenko/rke_airgap_install](https://github.com/clemenko/rke_airgap_install/blob/main/air_gap_all_the_things.sh). 
I tried it and the idea pleased me but I had small frustrations about the Shell scripting limitations. So I decided to rewrite it in Ansible.  

With Ansible:
- Idempotency: can be relaunch multiple time. 
- User agnostic: can be launch any user (with sudo rights). 
- OS agnositc: can be launch on any Linux systems (at least for the package build, for the install depend on your participation to this project)

Add-on from my part:
- Arkade to install utilities binaries
- Nerdctl (as complement of containerd) 
- Firewalld settings if firewalld is activated
- Uninstall playbook to cleanup (and maybe reinstall)

## Prerequisites

* Linux Host as a package builder (can be a VM or your WSL)

* 3 RHEL-like hosts for the cluster RKE2.

## Getting started

1. Clone the project on local machine which have an access.

2. Build your package by running:
```sh
ansible-playbook  playbooks/tasks/build.yml
```


## Roadmap
milestones:
- To deploy sone staffs
- To add flavors

Improvment:
- Add a option to chooce by url or by copy

## Authors
morze.baltyk@proton.me

## Project status
Still on developement
