# CHANGELOG.md

## 1.0.1 (unreleased)

Security:    

Features:    

Fix:    

Bugfixes: 
  - Firewalld conditions to apply only when running
  - Correct names and tasks order       

## 1.0.0 (2023-12-31)

**Init Ansible Collection**      

Features:
  - Install RKE2 one controler and several workers (currently no HA)
  - with nerdctl.
  - with an admin setup on master node (kuberoot).
  - with local registry and images loaded inside.
  - with firewalld rules if needed
  - with script to uninstall 
