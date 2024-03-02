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
  spaces_access_id  = var.spaces_access_key_id
  spaces_secret_key = var.spaces_access_key_secret
}

resource "digitalocean_spaces_bucket" "terraform_backend" {
  name   = var.terraform_backend_bucket_name
  region = var.region
  force_destroy = true
}

output "terraform_backend_bucket_domain_name" {
  value = digitalocean_spaces_bucket.terraform_backend.bucket_domain_name
}

output "terraform_backend_bucket_name" {
  value = digitalocean_spaces_bucket.terraform_backend.name
}

output "terraform_backend_bucket_region" {
  value = digitalocean_spaces_bucket.terraform_backend.region
}
