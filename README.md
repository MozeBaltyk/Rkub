<h1 style="text-align: center;"><code> Ansible Collection - Rkub  </code></h1>

Ansible Collection to deploy a RKE2 cluster in airgap mode with Rancher, Longhorn and Neuvector.

[![Releases](https://img.shields.io/github/release/MozeBaltyk/rkub)](https://github.com/MozeBaltyk/rkub/releases)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-green.svg)](https://opensource.org/licenses/Apache-2.0/)
[![Stage airgap](https://github.com/MozeBaltyk/Rkub/actions/workflows/stage.yml/badge.svg)](https://github.com/MozeBaltyk/Rkub/actions/workflows/stage.yml)

## Description

This Ansible collection will install in airgap environnement RKE2 (one controler and several workers, currently no HA):

<!-- Autogenerated -->
**Current develop - Ansible Collection Rkub 1.0.3 include:**

- [RKE2 1.27.10](https://docs.rke2.io) - Security focused Kubernetes (channel stable)

- [Kube-vip 0.7.0](https://kube-vip.io/) - Virtual IP and load balancer

- [Cert-manager 1.14.1](https://cert-manager.io/docs/) - Certificate manager

- [Rancher 2.8.1](https://www.suse.com/products/suse-rancher/) - Multi-Cluster Kubernetes Management

- [Longhorn 1.6.0](https://longhorn.io) - Unified storage layer

- [Neuvector 2.7.2](https://neuvector.com/) - Kubernetes Security Platform
<!-- END -->

This Project is mainly inspired from [Clemenko/rke_airgap_install](https://github.com/clemenko/rke_airgap_install/blob/main/air_gap_all_the_things.sh).
I tried it and like the idea but I was frustrated with Shell scripting limitations. So I decided to rewrite it in Ansible.

With Ansible:

- Idempotency: can be relaunch multiple time.

- User agnostic: can be launch by any user (with sudo rights).

- OS agnositc: can be launch on any Linux systems (at least for the package build, for the install depend on your participation to this project 😸)

Add-on from my part, some part which were manual in Clemenko procedure are automated with Ansible like:

- the upload or NFS mount

- Some flexibility about path (possible to export or mount NFS in choosen place)

- Arkade to install utilities binaries

- Admin user (by default kuberoot) on first controler node with all necessary tools

- Nerdctl (as complement of containerd to handle oci-archive)

- Firewalld settings if firewalld running

- Uninstall playbook to cleanup (and maybe reinstall if needed)

- Collection Released, so possibilty to get back to older versions

## Prerequisites

- Linux Host as a package builder (can be a VM or your WSL). Count 30G of free space in the build directory of your package builder (17G for download + 7G for the zst package).

- An Ansible Controler, can be the same host for ansible and for building package, at your convenience...

- A minimum of 2 hosts RHEL-like (2 vCPU and 8G of RAM) for the cluster RKE2 with 80G at least on target directory.

## Getting started

1. Preparation steps:

- Clone the main branch of this project to a machine with an internet access:
      `git clone -b main https://github.com/MozeBaltyk/Rkub.git`

- Execute `make prerequis` to install all prerequisites defined in meta directory.

- Complete directory inside `./plugins/inventory/hosts.yml`.

2. Build your package by running (works on Debian-like and Redhat-like and it targets localhost):

```sh
ansible-playbook playbooks/tasks/build.yml         # All arguments below are not mandatory
-e dir_build="$HOME/rkub"                          # Directory where to upload everything (count 30G)
-e package_name="rke2_rancher_longhorn.zst"        # Name of the package, by default rke2_rancher_longhorn.zst
-e archive="True"                                  # Archive tar.zst true or false (default value "true")
-u admin -Kk                                       # Other Ansible Arguments (like -vvv)
```

3. Push your package to first controler:

```sh
ansible-playbook playbooks/tasks/upload.yml        # All arguments below are not mandatory
-e package_path=/home/me/rke2_rancher_longhorn.zst # Will be prompt if not given in the command
-e dir_target=/opt                                 # Directory where to sync and unarchive (by default /opt, count 50G available)
-u admin -Kk                                       # Other Ansible Arguments (like -vvv)
```

4. Start installation:

```sh
ansible-playbook playbooks/tasks/install.yml       # All arguments below are not mandatory
-e dir_target=/opt                                 # Dir on first master where to find package unarchive by previous task (by default /opt, count 50G available)
-e dir_mount=/mnt/rkub                             # NFS mount point (on first master, it will be a symlink to "dir_target")
-e domain="example.com"                            # By default take the host domain from master server
-u admin -Kk                                       # Other Ansible Arguments (like -vvv)
```

5. Deploy Rancher:

```sh
ansible-playbook playbooks/tasks/rancher.yml       # All arguments below are not mandatory
-e dir_mount=/mnt/rkub                             # NFS mount point, by default value is /mnt/rkub
-e domain="example.com"                            # Domain use for ingress, by default take the host domain from master server
-e password="BootStrapAllTheThings"                # Default password is "BootStrapAllTheThings"
-u admin -Kk                                       # Other Ansible Arguments (like -vvv)
```

6. Deploy Longhorn:

```sh
ansible-playbook playbooks/tasks/longhorn.yml      # All arguments below are not mandatory
-e dir_mount=/mnt/rkub                             # NFS mount point, by default value is /mnt/rkub
-e domain="example.com"                            # Domain use for ingress, by default take the host domain from master server
-e datapath="/opt/longhorn"                        # Longhorn Path for PVC, by default equal "{{ dir_target }}/longhorn".
                                                   # The best is to have a dedicated LVM filesystem for this one.
-u admin -Kk                                       # Other Ansible Arguments (like -vvv)
```

7. Deploy Neuvector

```sh
ansible-playbook playbooks/tasks/neuvector.yml     # All arguments below are not mandatory
-e dir_mount=/mnt/rkub                             # NFS mount point, by default value is /mnt/rkub
-e domain="example.com"                            # Domain use for ingress, by default take the host domain from master server
-u admin -Kk                                       # Other Ansible Arguments (like -vvv)
```

8. Bonus:

With make command, all playbooks above are in the makefile. `make` alone display options and small descriptions.

```bash
# Example with make
make install                                       # All arguments below are not mandatory
ANSIBLE_USER=admin                                 # equal to '-u admin'
"OPT=-e domain=example.com -Kk"                    # redefine vars or add options to ansible-playbook command
```

## Container methode

1. This is a custom script which imitate Execution-Environement:

- `make ee-container` will load an UBI-8 image and execute inside `make prerequis`

- `make ee-exec` Run image with collection and package zst mounted inside. Launch playbook or make command as described above.

All prerequisites are set in folder `meta` and `meta/execution-environment.yml`. So it's possible to use ansible-builder (though not tested yet).

## Some details

**Build** have for purpose to create a tar zst with following content:

```bash
rkub
├── helm          # all helm charts
├── images        # all images
│   ├── cert
│   ├── longhorn
│   ├── neuvector
│   ├── rancher
│   └── registry
├── rke2_1.26.11  # RKE2 binaries
└── utils         # utilities packages downloaded with arkade
```

**upload** push the big monster packages (around 7G) and unarchive on first node on chosen targeted path.

**install** RKE2 (currently only one master) with:
  - An admin user (by default `kuberoot`) on first master with some administation tools like `k9s` `kubectl` or `helm`.
  - Master export NFS with all the unarchive content + registry content
  - Workers mount the NFS to get above content
  - A minimal registry is deploy on each nodes pointing to the NFS mount and responding to `localhost:5000`
  - Nerdctl as complement to containerd and allow oci-archive
  - Firewalld settings if firewalld running

**deploy** keeping this order, *Rancher*, *Longhorn*, *Neuvector*
  - Those are simple playbooks which deploy with helm charts
  - It use the default ingress from RKE2 *Nginx-ingress* in https (currently Self-sign certificate)
  - *Rancher* need *Certmanager*, So it deploy first Certmanager

## Roadmap

Milestones:

* More install customization and options

* HA masters with kubevip

* Add a option to chooce by url mode or airgap mode

Improvments:

* Improve collection to run as true collection

* CI

# Acknowledgements

## Special thanks to 📢

* Clemenko, for the idea [Clemenko/rke_airgap_install](https://github.com/clemenko/rke_airgap_install/blob/main/air_gap_all_the_things.sh).

* Alex Ellis, for its [Arkade project](https://github.com/alexellis/arkade). I cannot live without anymore.

## References:

- [Clemenko/rke_airgap_install](https://github.com/clemenko/rke_airgap_install/blob/main/air_gap_all_the_things.sh)

- [rancherfederal/RKE2-ansible](https://github.com/rancherfederal/rke2-ansible)

- [lablabs/ansible-role-rke2](https://github.com/lablabs/ansible-role-rke2)

- [rancher/RKE2](https://github.com/rancher/rke2)


Get the latest stable version:

```bash
## RKE2
curl -s https://raw.githubusercontent.com/rancher/rke2/master/channels.yaml | yq -N '.channels[] | select(.name == "stable") | .latest'

## K3S
curl -s https://raw.githubusercontent.com/k3s-io/k3s/master/channel.yaml | yq -N '.channels[] | select(.name == "stable") | .latest'
```

## Repo Activity
![Alt](https://repobeats.axiom.co/api/embed/2664e49768529526895630ae70e2a366a70de78f.svg "Repobeats analytics image")


## Project status
Still on developement
