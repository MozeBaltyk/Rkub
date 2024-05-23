variable "token" {
  description = "Azure API Token"
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

variable "az_user" {
  type    = string
  description = "user created on VM"
  default = "terraform"
}

variable "az_system" {
  type    = string
  description = "os used for VM"
  default = "rockylinux-8-x64"
}

variable "domain" {
  description = "Domain given to loadbalancer and VMs"
  default = "rkub.com"
}

variable "region" {
  description = "Unique bucket name for storing terraform backend data"
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
  description = "Unique bucket name for storing terraform backend data"
  default = "/opt/rkub"
}

##
## Azure credentials
##

variable "azure_subscription_id" {
  description = "Azure Subscription ID"
}

variable "azure_client_id" {
  description = "Azure Client ID"
}

variable "azure_client_secret" {
  description = "Azure Client Secret"
}

variable "azure_tenant_id" {
  description = "Azure tenant ID"
}
