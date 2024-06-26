variable "token" {
  description = "Digital Ocean API Token"
}

### s-2vcpu-4gb
variable "instance_size" {
  type = string
  description = "VM size"
  default = "s-2vcpu-4gb"
}

variable "controller_count" {
  type    = number
  description = "number of controllers"
  default = "1"
}

variable "worker_count" {
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

variable "domain" {
  description = "Domain given to loadbalancer and VMs"
  default = "rkub.com"
}

variable "region" {
  description = "DO location for all resources"
  default = "fra1"
}

variable "airgap" {
  description = "if airgap true, mount s3 bucket with rkub package"
  default = "true"
}

variable "GITHUB_RUN_ID" {
  type    = string
  description = "github run id"
  default = "quickstart"
}

variable "terraform_backend_bucket_name" {
  description = "Unique bucket name for storing terraform backend data"
  default = "terraform-backend-rkub-quickstart"
}

variable "mount_point" {
  description = "Mount point on VM to mount S3 bucket"
  default = "/opt/rkub"
}

variable "spaces_access_key_id" {
  description = "Digital Ocean Spaces Access ID"
}

variable "spaces_access_key_secret" {
  description = "Digital Ocean Spaces Access Key"
}
