<h1 style="text-align: center;"><code> Ansible Collection - Rkub  </code></h1>

Ansible Collection to deploy and test Rancher stacks (RKE2, Rancher, Longhorn and Neuvector).

[![Releases](https://img.shields.io/github/release/MozeBaltyk/rkub)](https://github.com/MozeBaltyk/rkub/releases)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-green.svg)](https://opensource.org/licenses/Apache-2.0/)
[![Stage airgap](https://github.com/MozeBaltyk/Rkub/actions/workflows/stage_airgap.yml/badge.svg)](https://github.com/MozeBaltyk/Rkub/actions/workflows/stage_airgap.yml)
[![Stage online](https://github.com/MozeBaltyk/Rkub/actions/workflows/stage_online.yml/badge.svg)](https://github.com/MozeBaltyk/Rkub/actions/workflows/stage_online.yml)

## Description

This Ansible collection will install in airgap environnement RKE2 (one controler and several workers, currently no HA):

<!-- Autogenerated -->
**Ansible Collection Rkub 1.0.3 include:**

- [RKE2 1.28.10](https://docs.rke2.io) - Security focused Kubernetes

- [Kube-vip 0.8.0](https://kube-vip.io/) - Virtual IP and load balancer

- [Cert-manager 1.14.1](https://cert-manager.io/docs/) - Certificate manager

- [Rancher 2.8.2](https://www.suse.com/products/suse-rancher/) - Multi-Cluster Kubernetes Management

- [Longhorn 1.6.2](https://longhorn.io) - Unified storage layer

- [Neuvector 2.7.7](https://neuvector.com/) - Kubernetes Security Platform
<!-- END -->

This Project is mainly inspired from [Clemenko/rke_airgap_install](https://github.com/clemenko/rke_airgap_install/) but Shell scripting brings limitations. So Let's rewrite it in Ansible which comes with below benefices:

- Idempotency: can be relaunch multiple time.

- User agnostic: can be launch by any user (with sudo rights).

- OS agnositc: can be launch on any Linux systems (at least for the package build, for the install part, it depends on your participation 😸)

Add-on from this Ansible collection:

- Some flexibility about path with the possibility to build and install on a choosen path.

- Admin user (by default 'kuberoot') on first controller node with some admin tools (k9s, helm and kubectl).

- Import kubeconfig on Ansible controller host and add it to kubecm if present (to be able to admin rke2 cluster from localhost).

- Nerdctl as complement of containerd to handle oci-archive.

- Uninstall playbook to cleanup (and maybe reinstall if needed).

- Ansible Collection Released, so possibilty to get back to older versions.

- Quickstart script to triggers an RKE2 cluster in Digital Ocean and delete it once required.

## Use Case

Currently only install:

- on Rocky8

- airgap or online install

- tarball or rpm method

- Defined versions or versions from Stable channels

- Canal CNI

- Digital Ocean

But the target would be to handle all the usecase below:

| OS     | Versions                    | Method         | CNI    | Cloud providers |  Cluster Arch         | Extra Install   |
|--------|-----------------------------|----------------|--------|-----------------|-----------------------|-----------------|
| Rocky8 | Defined in this collection  | airgap tarball | Canal  | Digital Ocean   | Standalone            | Kubevip         |
| Ubuntu | Stable channels             | airgap rpm     |        | AWS             | One Master, x Workers | Longhorn        |
|        | Custom                      | online tarball |        | Azure           | 3 Masters, x Workers  | Rancher         |
|        |                             | online rpm     |        |                 |                       | Neuvector       |

## Prerequisites

- Linux Host as a package builder (can be a VM or your WSL). Count 10G of free space in the build directory of your package builder.

- An Ansible Controler, can be the same host for ansible and for building package, at your convenience...

- A minimum of 2 hosts RHEL-like (2 vCPU and 8G of RAM) for the cluster RKE2 with 80G at least on target directory.

## Quickstart

As prerequisities, you will need a Digital Ocean accompte and set your `Token` and a `Spaces key` in Digital Ocean's API tabs.

Then perform those followings steps:

- Clone the main branch of this project to a machine with an internet access:
      `git clone -b main https://github.com/MozeBaltyk/Rkub.git`

- Execute `make prerequis` to install all prerequisites defined in meta directory.

- Export vars and Execute as below:

```bash
export DO_PAT="xxxxxxxxxx"
export AWS_ACCESS_KEY_ID="xxxxxxxxxxxx"
export AWS_SECRET_ACCESS_KEY="xxxxxxxxxxx"
export WORKERS=2 # Default 0
export MASTERS=3 # Default 1

# Create RKE2 cluster
make quickstart

# Delete RKE2 cluster
make cleanup

# Other components
make longhorn
make rancher
make neuvector
```

NB: Quickstart is meant to deploy in DO a quick RKE2 cluster for testing purpose, and without taking into account airgap problematics.
Airgap actions are adressed in below procedure.

## Global Usage

1. Preparatory steps for a normal ansible controller:

- Create some SSH keys and deploy it on target hosts.

- Define an ansible.cfg

- Define an inventory (example in `./plugins/inventory/hosts.yml`).

then use it...

2. Build your package by running (works on Debian-like or Redhat-like and targets localhost).
This step concern only an airgap install. If targeted servers have an internet access then skip and go to step 5:

```sh
ansible-playbook mozebaltyk.rkub.build.yml                    # All arguments below are not mandatory
-e "dir_build=$HOME/rkub"                                     # Directory where to upload everything (count 10G)
-e "package_name=rkub.zst"                                    # Name of the package, by default rkub.zst
-e "archive=true"                                             # Archive tar.zst true or false (default value "true")
-e "stable=false"                                             # Stable channels or take version as defined in Rkub collection (default value "false")
-e "method=tarball"                                           # Method for install, value possible "tarball" or "rpm" (default value "tarball")
-e "el=9"                                                     # RHEL version (take default value from localhost if OS is different from RedHat-like take value "8")
-e "all=false"                                                # Add all components kubevip,longhorn,rancher,neuvector (default value "false")
-e "kubevip=true longhorn=true rancher=true neuvector=true"   # Add extras components to package (default value from var 'all')
-u admin -Kk                                                  # Other Ansible Arguments (like -vvv)
```

3. Push your package to first controler:

```sh
ansible-playbook mozebaltyk.rkub.upload.yml        # All arguments below are not mandatory
-e "package_path=/home/me/rkub.zst"                # Will be prompt if not given in the command
-e "dir_target=/opt/rkub"                          # Directory where to sync and unarchive (by default /opt/rkub, count 30G available)
-u admin -Kk                                       # Other Ansible Arguments (like -vvv)
```

4. Deploy Hauler services:

```sh
ansible-playbook mozebaltyk.rkub.hauler.yml        # All arguments below are not mandatory
-e "dir_target=/opt/rkub"                          # Directory where to find package untar with previous playbook
-u admin -Kk                                       # Other Ansible Arguments (like -vvv)
```

5. Start installation:

```sh
ansible-playbook mozebaltyk.rkub.install.yml       # All arguments below are not mandatory
-e domain="example.com"                            # By default take the host domain from master server
-e "method=tarball"                                # Method for install, value possible "tarball" or "rpm" (default value "tarball")
-e "airgap=true"                                   # if servers have internet access then set airgap to false (default value "true")
  -e "stable=false"                                # if airgap false then choose btw Stable channels or version from this collection. (default value "false")
-u admin -Kk                                       # Other Ansible Arguments (like -vvv)
```

6. Deploy Rancher:

```sh
ansible-playbook mozebaltyk.rkub.rancher.yml       # All arguments below are not mandatory
-e domain="example.com"                            # Domain use for ingress, by default take the host domain from master server
-e password="BootStrapAllTheThings"                # Default password is "BootStrapAllTheThings"
-u admin -Kk                                       # Other Ansible Arguments (like -vvv)
```

7. Deploy Longhorn:

```sh
ansible-playbook mozebaltyk.rkub.longhorn.yml      # All arguments below are not mandatory
-e domain="example.com"                            # Domain use for ingress, by default take the host domain from master server
-e datapath="/data/longhorn"                       # Longhorn Path for PVC (default "/data/longhorn").
                                                   # The best is to have a dedicated LVM filesystem for this one.
-u admin -Kk                                       # Other Ansible Arguments (like -vvv)
```

8. Deploy Neuvector

```sh
ansible-playbook mozebaltyk.rkub.neuvector.yml     # All arguments below are not mandatory
-e domain="example.com"                            # Domain use for ingress, by default take the host domain from master server
-u admin -Kk                                       # Other Ansible Arguments (like -vvv)
```

## Ansible collection in Container

1. This is a custom script which imitate Execution-Environement:

- `make ee-container` will load an UBI-8 image and execute inside `make prerequis`

- `make ee-exec` Run image with collection and package zst mounted inside. Launch playbook or make command as described above.

All prerequisites are set in folder `meta` and `meta/execution-environment.yml`. So it's possible to use ansible-builder (though not tested yet).

## TLDR; few interesting details

I favored the tarball installation since it's the most compact and install rely on a archive tar.zst which stay on all nodes.
The rpm install is much straight forward and a bit faster but match only system with RPM (so mainly Redhat-like) and require a registry.
So because of this point, the rpm method with the rke2 stable channel is used for the quickstart install.

**build** have for purpose to create a tar.zst with following content using hauler tool:

```bash
rkub
├── airgap_hauler.yaml    # yaml listing all resources
├── hauler                # hauler binary
└── store                 # hauler store made from above yaml and hauler command
    ├── blobs
    │   └── sha256
    │       ├── 024f2ae6c3625583f0e10ab4d68e4b8947b55d085c88e34c0bd916944ed05add
    └── index.json
```

It will store and build package regarding:

- Chosen install method for rke2 (tarbal or rpm)
- Chosen components (kube-vip, longhorn, rancher, neuvector)
- Chosen channels stable or versions defined in this collection

**upload** push the big monster packages (around 7G) and unarchive on first node on chosen targeted path.

**hauler** (by default on first controller but could be on dedicated server)

- deploy a registry as systemd service and make it available on port 5000 using hauler.
- deploy a fileserver as systemd service and make it available on port 8080 using hauler.

**install** RKE2 (currently only one master) with:

- Install rke2 with tarball method by default or rpm method if given in argument.
- An admin user (by default `kuberoot`) on first master with some administation tools like `k9s` `kubectl` or `helm`.
- Nerdctl as complement to containerd and allow oci-archive.
- Firewalld settings if firewalld running.
- Selinux rpm if selinux enabled.
- Fetch and add kubeconfig to ansible controller in directory ./kube (and add to kubecm if present).

**deploy** keeping this order, *Rancher*, *Longhorn*, *Neuvector*

- Those are simple playbooks which deploy with helm charts either in airgap or online mode.
- It use the default ingress from RKE2 *Nginx-ingress* in https (currently Self-sign certificate)
- *Rancher* need *Certmanager*, So it deploy first Certmanager

## Roadmap

Milestones:

* More install customization and options

* HA masters with kubevip

* Allow several providers (currently only DO)

# Acknowledgements

## Special thanks to 📢

* Clemenko, for the idea [Clemenko/rke_airgap_install](https://github.com/clemenko/rke_airgap_install/).

## References

- [Clemenko/rke_airgap_install](https://github.com/clemenko/rke_airgap_install/)

- [rancherfederal/RKE2-ansible](https://github.com/rancherfederal/rke2-ansible)

- [lablabs/ansible-role-rke2](https://github.com/lablabs/ansible-role-rke2)

- [rancher/RKE2](https://github.com/rancher/rke2)

- [rancher/quickstart](https://github.com/rancher/quickstart)

## Repo Activity

![Alt](https://repobeats.axiom.co/api/embed/2664e49768529526895630ae70e2a366a70de78f.svg "Repobeats analytics image")

## Project status

Still on developement
