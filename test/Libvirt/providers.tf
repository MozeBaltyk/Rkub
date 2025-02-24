terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      #version = "0.7.6"
    }
  }
}

terraform {
  required_version = ">= 0.12"
}

provider "libvirt" {
  # Configuration du fournisseur libvirt
  uri = "qemu:///system"
  # uri = "qemu:///session"
  # uri = "qemu:///session?socket=/run/user/1000/libvirt/virtqemud-sock"
}