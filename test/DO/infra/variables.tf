variable "do_token" {
  description = "Digital Ocean API Token"
}

### s-2vcpu-4gb
variable "do_instance_size" {
  type = string
  description = "VM size"
  default = "s-1vcpu-1gb"
}

variable "do_controller_count" {
  type    = number
  description = "number of controllers"
  default = "1"
}

variable "do_worker_count" {
  type    = number
  description = "number of workers"
  default = "2"
}

variable "do_user" {
  type    = string
  description = "user created on droplet"
  default = "terraform"
}

variable "do_system" {
  type    = string
  description = "os used for droplet"
  default = "rockylinux-8-x64"
}

variable "region" {
  description = "Unique bucket name for storing terraform backend data"
  default = "fra1"
}

variable "GITHUB_RUN_ID" {
  type    = string
  description = "github run id"
  default = "test"
}

variable "terraform_backend_bucket_name" {
  description = "Unique bucket name for storing terraform backend data"
  default = "terraform-backend-github-${var.GITHUB_RUN_ID}"
}
