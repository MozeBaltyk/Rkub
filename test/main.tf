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
}

provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_ssh_key" "terraform" {
  name = "terraform"
}

###
### VPC
###
resource "digitalocean_vpc" "fra1-vpc-01" {
  name     = "rkub-project-network"
  region   = "fra1"
  ip_range = "10.10.10.0/24"
}

###
### Droplet INSTANCES
###

# Droplet Instance for RKE2 Cluster - Manager
resource "digitalocean_droplet" "controllers" {
    count = 1
    image = var.do_system
    name = "controller${count.index}"
    region = "fra1"
    size = var.do_instance_size
    tags   = [
      "rke2_ansible_test_on_${var.do_system}_${var.GITHUB_RUN_ID}_controllers",
      ]
    vpc_uuid = digitalocean_vpc.fra1-vpc-01.id
    ssh_keys = [
      data.digitalocean_ssh_key.terraform.id
    ]

  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    private_key = file(pathexpand(".key"))
    timeout = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "cat /etc/os-release",
    ]
  }
}

output "ip_address_controllers" {
  value = digitalocean_droplet.controllers[*].ipv4_address
  description = "The public IP address of your rke2 controllers."
}


# Droplet Instance for RKE2 Cluster - Workers
resource "digitalocean_droplet" "workers" {
    count = 2
    image = var.do_system
    name = "worker${count.index}"
    region = "fra1"
    size = var.do_instance_size
    tags   = [
      "rke2_ansible_test_on_${var.do_system}_${var.GITHUB_RUN_ID}_workers",
      ]
    vpc_uuid = digitalocean_vpc.fra1-vpc-01.id
    ssh_keys = [
      data.digitalocean_ssh_key.terraform.id
    ]

  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    private_key = file(pathexpand(".key"))
    timeout = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "cat /etc/os-release",
    ]
  }
}

output "ip_address_workers" {
  value = digitalocean_droplet.workers[*].ipv4_address
  description = "The public IP address of your rke2 workers."
}

###
### Project
###

resource "digitalocean_project" "rkub" {
  name        = "Rkub-${var.GITHUB_RUN_ID}"
  description = "A CI project to test the Rkub development from github."
  purpose     = "Cluster k8s"
  environment = "Staging"
  resources = flatten([digitalocean_droplet.controllers.*.urn, digitalocean_droplet.workers.*.urn])
}
