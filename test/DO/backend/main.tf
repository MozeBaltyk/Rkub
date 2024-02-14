terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

resource "digitalocean_spaces_bucket" "terraform_backend" {
  name   = var.terraform_backend_bucket_name
  region = "fra1"
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
