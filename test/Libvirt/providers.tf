terraform {
  required_version = ">= 0.12"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = ">= 0.7.6"
    }
  }

  backend "s3" {
    # Configure your backend settings here as needed
    # Example:
    # bucket = "your-terraform-state-bucket"
    # key    = "libvirt/terraform.tfstate"
    # region = "your-region"
    skip_region_validation = true
    region                 = "fra1"
  }
}

provider "libvirt" {
  uri = "qemu:///system"
  # Uncomment and modify the following lines if alternative URIs are needed
  # uri = "qemu:///session"
  # uri = "qemu:///session?socket=/run/user/1000/libvirt/virtqemud-sock"
}
