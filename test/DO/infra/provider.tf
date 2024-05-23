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
    // Nothing here can be variabilized
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
    key                         = "terraform.tfstate"
  }
}

provider "digitalocean" {
  token = var.token
}
