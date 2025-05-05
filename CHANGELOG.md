# CHANGELOG.md

<!-- Release -->
## 1.0.6 (2025-05-05)

### Versions:

- rke2 version: 1.31.4

- kube-vip version: 0.8.7

- cert-manager version: 1.16.2

- rancher version: 2.11.1

- longhorn version: 1.7.2
  
- neuvector version: 5.3.4

<!-- End Release -->

<!-- Features -->
### Features ✨
  - [x] Install RKE2 one controler and several workers (currently no HA):
    - [x] Add nerdctl.
    - [x] Setup an admin on master node (kuberoot).
    - [x] Deploy local registry and images loaded inside.
    - [x] Setup firewalld rules if needed.
    - [x] Make "master_ip" and "domain" parametrable.
  - [x] Deploy longhorn with custom datapath.
  - [x] Deploy Rancher with custom password.
  - [x] Deploy Neuvector.
  - [x] Script to containerize in an Execution-Env.
  - [x] Script to uninstall everything
  - [x] More install customization and options
  - [x] Improve collection to run as true collection
  - [x] CI workflows
  - [x] Quickstart script
  - [x] Infra script for KVM or DO, to launch custom ansible-playbooks

Use case:
  - [x] airgap
  - [x] non-airgap
  - [x] standalone
  - [x] one-master-and-x-workers
  - [ ] masters-HA 🚧
  - [ ] update/upgrade 🚧
  - [ ] change-config 🚧
<!-- End Features -->

<!-- Fix -->
### Fix 🩹
  - Firewalld conditions to apply only when running.
  - Correct names and tasks order.
<!-- End Fix -->

<!-- Bugfix -->
### Bugfix 🐞
  - Correct scripts for prerequisites.
<!-- End Bugfix -->

<!-- Security -->
### Security 🔒️
  - Branch protect
  - Github Workflows to release and lint.
<!-- End Security -->
