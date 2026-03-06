terraform {
  required_version = ">= 0.12"

  required_providers {
    libvirt = {
      source  = "multani/libvirt"
      version = "0.6.3-1+4"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
  # Uncomment and modify the following lines if alternative URIs are needed
  # uri = "qemu:///session"
  # uri = "qemu:///session?socket=/run/user/1000/libvirt/virtqemud-sock"
}
