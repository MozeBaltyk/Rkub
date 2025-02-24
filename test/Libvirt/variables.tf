# Version Selection
variable "selected_version" {
  description = "Selected OS version"
  default     = "fedora40_local"  # Can be changed to "fedora41" as needed
}

# Version Mapping
variable "Versionning" {
  type = map(object({
    os_name            = string
    os_version_short   = number
    os_version_long    = string
    os_URL             = string
    cloud_init_version = number
  }))
  default = {
    fedora40 = {
      os_name            = "fedora"
      os_version_short   = 40
      os_version_long    = "40.1.14"
      os_URL             = "https://dl.fedoraproject.org/pub/fedora/linux/releases/40/Cloud/x86_64/images/Fedora-Cloud-Base-Generic.x86_64-40-1.14.qcow2"
      cloud_init_version = 24.4
    }
    fedora41 = {
      os_name            = "fedora"
      os_version_short   = 41
      os_version_long    = "41.1.4"
      os_URL             = "https://download.fedoraproject.org/pub/fedora/linux/releases/41/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-41-1.4.x86_64.qcow2"
      cloud_init_version = 24.4
    }
    fedora40_local = {
      os_name            = "fedora"
      os_version_short   = 40
      os_version_long    = "40.1.14"
      os_URL             = "file:///var/lib/libvirt/images/fedora40.qcow2"
      cloud_init_version = 24.4
    }
    fedora41_local = {
      os_name            = "fedora"
      os_version_short   = 41
      os_version_long    = "41.1.4"
      os_URL             = "file:///var/lib/libvirt/images/fedora41.qcow2"
      cloud_init_version = 24.4
    }
    rhel9_local ={
      os_name            = "redhat"
      os_version_short   = 9
      os_version_long    = "9.5"
      os_URL             = "file:///var/lib/libvirt/images/rhel95.qcow2"
      cloud_init_version = 24.4
    }
  }
}

# VM Configuration Variables
variable "rh_username" {
  description = "Red Hat username"
  default     = "rhel"
}

variable "rh_password" {
  description = "Red Hat password"
  default     = "redhat"
}

variable "pool" {
  description = "Libvirt storage pool name"
  default     = "rkub"
}

variable "clusterid" {
  description = "Cluster ID"
  default     = "rkub"
}

variable "domain" {
  description = "Domain for the cluster"
  default     = "local"
}

variable "ip_type" {
  description = "Type of IP assignment (e.g., dhcp)"
  default     = "dhcp"  # Other valid types are 'static', etc.
}

variable "network_name" {
  description = "Libvirt network name"
  default     = "rkub"
}

variable "network_cidr" {
  description = "CIDR for the Libvirt network"
  default     = "192.168.100.0/24"
}

variable "memoryMB" {
  description = "Memory for each VM in MB"
  default     = 4096
}

variable "cpu" {
  description = "Number of CPUs for each VM"
  default     = 2
}

variable "timezone" {
  description = "Timezone for the VMs"
  default     = "Europe/Paris"
}

variable "masters_number" {
  description = "Number of master nodes"
  default     = 3
}

variable "workers_number" {
  description = "Number of worker nodes"
  default     = 0
}

variable "masters_mac_addresses" {
  description = "List of MAC addresses for master nodes"
  type        = list(string)
  default     = ["52:54:00:36:14:e5", "52:54:00:36:14:e6", "52:54:00:36:14:e7"]
}

variable "workers_mac_addresses" {
  description = "List of MAC addresses for worker nodes"
  type        = list(string)
  default     = ["52:54:00:c8:7a:7a", "52:54:00:90:44:86"]
}

variable "product" {
  description = "Name of the product"
  default     = "rkub"
}

variable "release_version" {
  description = "Release version of the product"
  default     = "v1.0"
}

# Local Settings
locals {
  qcow2_image         = lookup(var.Versionning[var.selected_version], "os_URL", "")
  cloud_init_version  = lookup(var.Versionning[var.selected_version], "cloud_init_version", 0)
  subdomain           = "${var.clusterid}.${var.domain}"
  gateway_ip          = cidrhost(var.network_cidr, 1)
  broadcast_ip        = cidrhost(var.network_cidr, -1)
  netmask             = cidrnetmask(var.network_cidr)
  poolstart           = cidrhost(var.network_cidr, 10)
  poolend             = cidrhost(var.network_cidr, -2)
  ipid                = cidrhost(var.network_cidr, 0)
  os_name             = lookup(var.Versionning[var.selected_version], "os_name", "")
  os_version_short    = lookup(var.Versionning[var.selected_version], "os_version_short", "")
  rkub_pool_path      = "/var/lib/libvirt/images/${var.pool}"
  
  master_details = tolist([
    for a in range(var.masters_number) : {
      name = format("master%02d", a + 1)
      mac  = var.masters_mac_addresses[a]
    }
  ])
  
  worker_details = tolist([
    for b in range(var.workers_number) : {
      name = format("worker%02d", b + 1)
      mac  = var.workers_mac_addresses[b]
    }
  ])
}
