# CHANGELOG.md

<!-- Release -->
<!-- End Release -->
<!-- Features -->
<!-- End Features -->

## 1.0.1 (2024-01-02)

Version:
  - rke2 version: 1.26.11
  - cert-manager version: 1.13.3    
  - rancher version: 2.8.0 
  - longhorn version: 1.5.3
  - neuvector version: 2.6.6

Features:    
  - Make "master_ip" and "domain" parametrable
  - Deploy longhorn with custom datapath
  - Deploy Rancher with custom password
  - Deploy Neuvector

Fix:    
  - Firewalld conditions to apply only when running.
  - Correct names and tasks order.        

## 1.0.0 (2023-12-31)

**Init Ansible Collection**      

Features:
  - Install RKE2 one controler and several workers (currently no HA).
  - with nerdctl.
  - with an admin setup on master node (kuberoot).
  - with local registry and images loaded inside.
  - with firewalld rules if needed.
  - with script to uninstall.
