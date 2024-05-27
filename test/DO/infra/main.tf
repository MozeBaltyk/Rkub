# Digital Ocean Infrastructure Resources

###
### SSH
###

# Generate an SSH key pair
resource "tls_private_key" "global_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save the public key to a local file
resource "local_file" "ssh_public_key" {
  filename = "${path.module}/.key.pub"
  content  = tls_private_key.global_key.public_key_openssh
}

# Save the private key to a local file
resource "local_sensitive_file" "ssh_private_key" {
  filename        = "${path.module}/.key.private"
  content         = tls_private_key.global_key.private_key_pem
  file_permission = "0600"
}

# Upload the public key to DigitalOcean
resource "digitalocean_ssh_key" "ssh_key" {
  name       = "rkub-${var.GITHUB_RUN_ID}-ssh"
  public_key = tls_private_key.global_key.public_key_openssh
}
 
###
### VPC
###
resource "digitalocean_vpc" "rkub-project-network" {
  name     = "rkub-${var.GITHUB_RUN_ID}-network"
  region   = var.region

  timeouts {
    delete = "10m"
  }
}

# https://github.com/digitalocean/terraform-provider-digitalocean/issues/446
resource "time_sleep" "wait_for_vpc" {
  depends_on = [digitalocean_vpc.rkub-project-network]
  destroy_duration = "200s" # Adjust duration as needed
  create_duration = "30s"  # Adjust duration as needed
}
resource "null_resource" "placeholder" {
  depends_on = [time_sleep.wait_for_vpc]
}
#

###
### Droplet INSTANCES
###

# Droplet Instance for RKE2 Cluster - Manager
resource "digitalocean_droplet" "controllers" {
    count = var.controller_count
    image = var.do_system
    name = "controller${count.index}.${var.domain}"
    region = var.region
    size = var.instance_size
    tags   = [
      "rkub-${var.GITHUB_RUN_ID}",
      "controller",
      "${var.do_system}_controllers",
      ]
    vpc_uuid = digitalocean_vpc.rkub-project-network.id
    ssh_keys = [ digitalocean_ssh_key.ssh_key.fingerprint ]
    # if airgap, S3 bucket is mounted on master to get the resources
    user_data = var.airgap ? data.cloudinit_config.server_airgap_config.rendered : null
    depends_on = [ null_resource.placeholder, digitalocean_ssh_key.ssh_key ] # Ensure VPC and SSH key are created first
}

# Droplet Instance for RKE2 Cluster - Workers
resource "digitalocean_droplet" "workers" {
    count = var.worker_count
    image = var.do_system
    name = "worker${count.index}.${var.domain}"
    region = var.region
    size = var.instance_size
    tags   = [
      "rkub-${var.GITHUB_RUN_ID}",
      "worker",
      "${var.do_system}_workers",
      ]
    vpc_uuid = digitalocean_vpc.rkub-project-network.id
    ssh_keys = [ digitalocean_ssh_key.ssh_key.fingerprint ]
    depends_on = [ null_resource.placeholder, digitalocean_ssh_key.ssh_key ] # Ensure VPC and SSH key are created first
}

###
### Project
###
resource "digitalocean_project" "rkub" {
  name        = "rkub-${var.GITHUB_RUN_ID}"
  description = "A CI project to test the Rkub development from github."
  purpose     = "Cluster k8s"
  environment = "Staging"
  resources = flatten([digitalocean_droplet.controllers.*.urn, digitalocean_droplet.workers.*.urn ])
}
