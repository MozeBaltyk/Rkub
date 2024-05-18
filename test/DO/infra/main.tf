###
### Provider part
###
terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
  backend "s3" {
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    use_path_style              = true
    skip_s3_checksum            = true
    endpoints = {
      s3 = "https://fra1.digitaloceanspaces.com"
    }
    region                      = "fra1"
    // bucket                   = "terraform-backend-github"
    key                         = "terraform.tfstate"
  }
}

provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_ssh_key" "terraform" {
  name = "terraform"
}

###
### LB / Domain / DNS
###

resource "digitalocean_loadbalancer" "www-lb" {
  name = "rkub-${var.GITHUB_RUN_ID}-lb"
  region = var.region

  forwarding_rule {
    entry_port = 80
    entry_protocol = "http"

    target_port = 80
    target_protocol = "http"
  }

  healthcheck {
    port = 22
    protocol = "tcp"
  }

  droplet_ids = flatten([digitalocean_droplet.controllers.*.id])
  vpc_uuid = digitalocean_vpc.rkub-project-network.id
}
resource "digitalocean_domain" "rkub-domain" {
   name = var.domain
   ip_address = digitalocean_loadbalancer.www-lb.ip
}

resource "digitalocean_record" "wildcard" {
  domain = "${digitalocean_domain.rkub-domain.name}"
  type   = "A"
  name   = "*"
  value  = digitalocean_loadbalancer.www-lb.ip
}

###
### VPC
###
resource "digitalocean_vpc" "rkub-project-network" {
  name     = "rkub-${var.GITHUB_RUN_ID}-network"
  region   = var.region

  timeouts {
    delete = "30m"
  }
}

# https://github.com/digitalocean/terraform-provider-digitalocean/issues/446
resource "time_sleep" "wait_300_seconds_to_destroy" {
  depends_on = [digitalocean_vpc.rkub-project-network]
  destroy_duration = "300s"
}
resource "null_resource" "placeholder" {
  depends_on = [time_sleep.wait_300_seconds_to_destroy]
}
#


###
### Cloud-init
###
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
      "s3fs-fuse",
      "git",
      "ansible",
      "make"
    ],
    write_files = [{
      owner       = "root:root"
      path        = "/etc/passwd-s3fs"
      permissions = "0600"
      content     = "${var.spaces_access_key_id}:${var.spaces_access_key_secret}"
    }],
    runcmd = [
      "systemctl daemon-reload",
      "mkdir -p ${var.mount_point}",
      "s3fs ${var.terraform_backend_bucket_name} ${var.mount_point} -o url=https://${var.region}.digitaloceanspaces.com",
      "echo \"s3fs#${var.terraform_backend_bucket_name} ${var.mount_point} fuse _netdev,allow_other,nonempty,use_cache=/tmp/cache,url=https://${var.region}.digitaloceanspaces.com 0 0\" >> /etc/fstab",
      "systemctl daemon-reload",
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

###
### Droplet INSTANCES
###

# Droplet Instance for RKE2 Cluster - Manager
resource "digitalocean_droplet" "controllers" {
    count = var.do_controller_count
    image = var.do_system
    name = "controller${count.index}.${var.domain}"
    region = var.region
    size = var.do_instance_size
    tags   = [
      "rkub-${var.GITHUB_RUN_ID}",
      "controller",
      "${var.do_system}_controllers",
      ]
    vpc_uuid = digitalocean_vpc.rkub-project-network.id
    ssh_keys = [ data.digitalocean_ssh_key.terraform.id ]
    user_data = data.cloudinit_config.server_config.rendered
}

output "ip_address_controllers" {
  value = digitalocean_droplet.controllers[*].ipv4_address
  description = "The public IP address of your rke2 controllers."
}

# Droplet Instance for RKE2 Cluster - Workers
resource "digitalocean_droplet" "workers" {
    count = var.do_worker_count
    image = var.do_system
    name = "worker${count.index}.${var.domain}"
    region = var.region
    size = var.do_instance_size
    tags   = [
      "rkub-${var.GITHUB_RUN_ID}",
      "worker",
      "${var.do_system}_workers",
      ]
    vpc_uuid = digitalocean_vpc.rkub-project-network.id
    ssh_keys = [
      data.digitalocean_ssh_key.terraform.id
    ]
}

###
### Project
###
resource "digitalocean_project" "rkub" {
  name        = "rkub-${var.GITHUB_RUN_ID}"
  description = "A CI project to test the Rkub development from github."
  purpose     = "Cluster k8s"
  environment = "Staging"
  resources = flatten([digitalocean_droplet.controllers.*.urn, digitalocean_droplet.workers.*.urn])
}

###
### Generate the hosts.ini file
###
resource "local_file" "ansible_inventory" {
  content = templatefile("../../inventory/hosts.tpl",
    {
     controller_ips = digitalocean_droplet.controllers[*].ipv4_address,
     worker_ips     = digitalocean_droplet.workers[*].ipv4_address
    }
  )
  filename = "../../inventory/hosts.ini"
}

###
### Display
###
output "ip_address_workers" {
  value = digitalocean_droplet.workers[*].ipv4_address
  description = "The public IP address of your rke2 workers."
}
