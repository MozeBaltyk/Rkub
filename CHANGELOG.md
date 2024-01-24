# CHANGELOG.md

<!-- Release -->
## 1.0.3 (2024-01-24)

### Versions:
  - rke2 version: 1.26.11
  - cert-manager version: 1.13.0
  - rancher version: 2.8.0
  - longhorn version: 1.5.3
  - neuvector version: 2.6.6
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
  - [ ] More install customization and options 🚧
  - [ ] Improve collection to run as true collection 🚧
  - [ ] CI 🚧
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
