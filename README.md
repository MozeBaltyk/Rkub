<h1 style="text-align: center;"><code> Ansible Collection - MozeBaltyk.rkub  </code></h1>

Ansible Collection to deploy a rancher RKE2 cluster.

[![Releases](https://img.shields.io/github/release/MozeBaltyk/rkub)](https://github.com/MozeBaltyk/rkub/releases)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-green.svg)](https://opensource.org/licenses/Apache-2.0/)

## Check List
- Fill up this Readme
- Do a makefile or a justfile (pretty usefull for github/workflows or gitlab-ci)
- Update the version of this collection in galaxy.yml 
- Complete the changelog.md
- Put all dependencies to use this collection in deps/bindeps.txt, deps/requirements.yml, deps/requirements.txt, deps/arkade.txt and deps/images.txt
- when I do a "make prerequis", it should load all the dependencies (used for the build of the container)
- Release your version in github

## Description

This Project have for goal to deploy a Example APP using IAC (Infrastructure as Code)

**IMPORTANT:**  if your collections contain binaries list the version of those binaires in each version of your collection. 

Version namespace-example-1.0.0.tar.gz: 
- Cassandra 3.8.12
- Mariadb  10.9.3

## Prerequisites

Linux Host as Installer (can be a VM or your WSL) with following tools:
- Git
- make (by default installed on most Linux distributions)
- Packer
- Terraform
- Ansible-core 2.12.0

## Getting started

1. Clone this project
```sh
git clone https://github.com/Namespace/example.git 
```

2. Define your inventory respecting the template in ./plugins/inventory/hosts.yml
   NotaBene: you can change it directly in ./plugins/inventory/hosts.yml or give your own custom inventory!

```sh
# You can check your inventory with:
ansible-inventory --graph EXAMPLE
ansible-inventory --graph INSTANCE01
```

3. Kustomize your variables inside ./playbooks/vars/main.yml or in the inventory's group_vars.

4. Use it
```sh
make          # Give the command available
make help     # Give a more details about options available
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
