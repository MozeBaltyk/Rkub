terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_ssh_key" "terraform" {
  name = "terraform"
}

locals {
  cloud_init_config = yamlencode({
    yum_repos = {
      epel-release = {
        name = "Extra Packages for Enterprise Linux 8 - Release"
        baseurl = "http://download.fedoraproject.org/pub/epel/8/Everything/$basearch"
        enabled = true
        failovermethod = "priority"
        gpgcheck = true
        gpgkey = "http://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-8"
      }
    },
    packages = [
      "epel-release",
      "s3fs-fuse"
    ],
    write_files = [{
      owner       = "root:root"
      path        = "/etc/passwd-s3fs"
      permissions = "0600"
      content     = "${var.spaces_access_key_id}:${var.spaces_access_key_secret}"
    }],
    runcmd = [
      "mkdir -p ${var.mount_point}",
      "s3fs ${var.terraform_backend_bucket_name} ${var.mount_point} -o url=https://${var.region}.digitaloceanspaces.com",
      "git clone https://github.com/MozeBaltyk/Rkub.git",
    ]
  })
}

# Convert our cloud-init config to userdata
# Userdata runs at first boot when the droplets are created
data "cloudinit_config" "server_config" {
  gzip          = false
  base64_encode = false
  part {
    content_type = "text/cloud-config"
    content      = local.cloud_init_config
  }
}

resource "digitalocean_droplet" "ansible" {
  image  = "rockylinux-8-x64"
  name   = "ansible"
  region = var.region
  size   = var.do_instance_size
  ssh_keys = [ data.digitalocean_ssh_key.terraform.id ]
  user_data = data.cloudinit_config.server_config.rendered
#  connection {
#    host = self.ipv4_address
#    user = "root"
#    type = "ssh"
#    private_key = file(pathexpand(".key"))
#    timeout = "2m"
#  }
#  provisioner "remote-exec" {
#    inline = [
#      "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -vv --private-key .key ../../playbooks/build.yml",
#    ]
#  }
}

output "ip_address_ansible" {
  value = digitalocean_droplet.ansible[*].ipv4_address
  description = "The public IP address of your ansible server."
}
