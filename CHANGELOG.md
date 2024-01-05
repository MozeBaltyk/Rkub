# CHANGELOG.md

<!-- Release -->
## 1.0.0 (2024-01-05)

Versions:
  - rke2 version: 1.26.11
  - cert-manager version: 1.13.3    
  - rancher version: 2.8.0 
  - longhorn version: 1.5.3
  - neuvector version: 2.6.6
<!-- End Release -->

<!-- Features -->
Features:
  - Install RKE2 one controler and several workers (currently no HA):
    - Add nerdctl.
    - Setup an admin on master node (kuberoot).
    - Deploy local registry and images loaded inside.
    - Setup firewalld rules if needed.
    - Make "master_ip" and "domain" parametrable
  - Script to uninstall everything. 
  - Deploy longhorn with custom datapath
  - Deploy Rancher with custom password
  - Deploy Neuvector
  - Github Workflows to release
<!-- End Features -->

<!-- Fix -->
Fix:    
  - Firewalld conditions to apply only when running.
  - Correct names and tasks order.
<!-- End Fix -->

<!-- Bugfix -->
<!-- End Bugfix -->

<!-- Security -->
<!-- End Security -->
