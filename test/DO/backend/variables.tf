variable "token" {
  description = "Digital Ocean API Token"
}

variable "spaces_access_key_id" {
  description = "Digital Ocean Spaces Access ID"
}

variable "spaces_access_key_secret" {
  description = "Digital Ocean Spaces Access Key"
}

variable "GITHUB_RUN_ID" {
  type    = string
  description = "github run id"
  default = "test"
}

variable "terraform_backend_bucket_name" {
  description = "Unique bucket name for storing terraform backend data"
  default = "terraform-backend-rkub-quickstart"
}

variable "region" {
  description = "Unique bucket name for storing terraform backend data"
  default = "fra1"
}
