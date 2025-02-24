terraform {
  required_version = ">= 0.12"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = ">= 0.7.6"
    }
  }

  backend "s3" {
    # バックエンド設定を必要に応じて構成してください
    # 例:
    # bucket = "your-terraform-state-bucket"
    # key    = "libvirt/terraform.tfstate"
    # region = "your-region"
    skip_region_validation = true
    region                 = "fra1"
  }
}

provider "libvirt" {
  uri = "qemu:///system"
  # 別のURIが必要な場合はコメントを外してください
  # uri = "qemu:///session"
  # uri = "qemu:///session?socket=/run/user/1000/libvirt/virtqemud-sock"
}
