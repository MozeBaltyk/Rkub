# CHANGELOG.md

<!-- Release -->
## 1.0.3 (2024-01-15)

Versions:
  - rke2 version: 1.26.11
  - cert-manager version: 1.13.3    
  - rancher version: 2.8.0 
  - longhorn version: 1.5.3
  - neuvector version: 2.6.6
<!-- End Release -->

<!-- Features -->
Features ✨
  - Install RKE2 one controler and several workers (currently no HA):
    - Add nerdctl.
    - Setup an admin on master node (kuberoot).
    - Deploy local registry and images loaded inside.
    - Setup firewalld rules if needed.
    - Make "master_ip" and "domain" parametrable.
  - Deploy longhorn with custom datapath.
  - Deploy Rancher with custom password.
  - Deploy Neuvector.
  - Script to containerize in an Execution-Env.
  - Script to uninstall everything
<!-- End Features -->

<!-- Fix -->
Fix 🩹    
  - Firewalld conditions to apply only when running.
  - Correct names and tasks order.
<!-- End Fix -->

<!-- Bugfix -->
Bugfix 🐞
  - Correct scripts for prerequisites.
<!-- End Bugfix -->

<!-- Security -->
Security 🔒️
  - Branch protect
  - Github Workflows to release and lint.
<!-- End Security -->
