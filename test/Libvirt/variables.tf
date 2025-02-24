# バージョン選択
variable "selected_version" {
  description = "選択されたOSバージョン"
  default     = "fedora40_local"  # 必要に応じて "fedora41" に変更可能
}

# バージョンマッピング
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

# VM構成変数
variable "hostname" {
  description = "VMの基本ホストネーム"
  default     = "node"
}

variable "rh_username" {
  description = "Red Hatのユーザー名"
  default     = "rhel"
}

variable "rh_password" {
  description = "Red Hatのパスワード"
  default     = "redhat"
}

variable "pool" {
  description = "Libvirtストレージプール名"
  default     = "default"
}

variable "clusterid" {
  description = "クラスタID"
  default     = "ocp4"
}

variable "domain" {
  description = "クラスタのドメイン"
  default     = "local"
}

variable "ip_type" {
  description = "IP割り当てのタイプ（例: dhcp）"
  default     = "dhcp"  # 他の有効なタイプは 'static' など
}

variable "network_name" {
  description = "Libvirtネットワーク名"
  default     = "openshift4"
}

variable "network_cidr" {
  description = "LibvirtネットワークのCIDR"
  default     = "192.168.100.0/24"
}

variable "helper_mac_address" {
  description = "ヘルパーVMのMACアドレス"
  default     = "52:54:00:36:14:e5"
}

variable "memoryMB" {
  description = "各VMのメモリ（MB）"
  default     = 4096
}

variable "cpu" {
  description = "各VMのCPU数"
  default     = 2
}

variable "timezone" {
  description = "VMのタイムゾーン"
  default     = "Europe/Paris"
}

variable "masters_number" {
  description = "マスターノードの数"
  default     = 3
}

variable "workers_number" {
  description = "ワーカーノードの数"
  default     = 2
}

variable "masters_mac_addresses" {
  description = "マスターノードのMACアドレスリスト"
  type        = list(string)
  default     = ["52:54:00:36:14:e5", "52:54:00:36:14:e6", "52:54:00:36:14:e7"]
}

variable "workers_mac_addresses" {
  description = "ワーカーノードのMACアドレスリスト"
  type        = list(string)
  default     = ["52:54:00:c8:7a:7a", "52:54:00:90:44:86"]
}

# ローカル設定
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
  
  master_details = tolist([
    for a in range(var.masters_number) : {
      name = format("master%02d", a + 1)
      ip   = cidrhost(var.network_cidr, a + 10)
      mac  = var.masters_mac_addresses[a]
    }
  ])
  
  worker_details = tolist([
    for b in range(var.workers_number) : {
      name = format("worker%02d", b + 1)
      ip   = cidrhost(var.network_cidr, b + 20)
      mac  = var.workers_mac_addresses[b]
    }
  ])
}
