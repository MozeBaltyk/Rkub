# Fetch the OS image from local storage
resource "libvirt_volume" "os_image" {
  name   = "${var.hostname}-${var.selected_version}-os_image"
  pool   = var.pool
  source = local.qcow2_image
  format = "qcow2"
}

# Use CloudInit ISO to add SSH key to the instances
resource "libvirt_cloudinit_disk" "commoninit" {
  count          = var.masters_number + var.workers_number
  name           = "${var.hostname}-${var.selected_version}-commoninit-${count.index}.iso"
  pool           = var.pool
  user_data      = data.template_cloudinit_config.config.rendered
  network_config = data.template_file.network_config.rendered
}

### Pool
resource "libvirt_pool" "rkub_pool" {
  name = var.pool
  type = "dir"
  target {
    path = local.rkub_pool_path
  }
}

### TLS Private Key
resource "tls_private_key" "global_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

### Disks
# Define libvirt volumes for master nodes
resource "libvirt_volume" "master_disk" {
  for_each = { for idx, master in local.master_details : idx => master }
  name     = "${each.value.name}-disk-${var.product}-${var.release_version}.qcow2"
  pool     = libvirt_pool.rkub_pool.name
  size     = 30 * 1024 * 1024 * 1024  # 30 GB in bytes
  format   = "qcow2"
}

# Define libvirt volumes for worker nodes
resource "libvirt_volume" "worker_disk" {
  for_each = { for idx, worker in local.worker_details : idx => worker }
  name     = "${each.value.name}-disk-${var.product}-${var.release_version}.qcow2"
  pool     = libvirt_pool.rkub_pool.name
  size     = 30 * 1024 * 1024 * 1024  # 30 GB in bytes
  format   = "qcow2"
}

# Define Libvirt network
resource "libvirt_network" "network" {
  name      = var.network_name
  mode      = "nat"
  bridge    = "virbr7"
  autostart = true
  domain    = local.subdomain
  addresses = [var.network_cidr]
  
  dhcp {
    enabled = true
  }
}

# Template for user data
data "template_file" "user_data" {
  template = file("${path.module}/24.4/cloud_init.cfg.tftpl")
  vars = {
    os_name        = local.os_name
    hostname       = var.hostname
    fqdn           = "${var.hostname}.${local.subdomain}"
    domain         = local.subdomain
    clusterid      = var.clusterid
    timezone       = var.timezone
    gateway_ip     = local.gateway_ip
    broadcast_ip   = local.broadcast_ip
    netmask        = local.netmask
    network_cidr   = var.network_cidr
    poolstart      = local.poolstart
    poolend        = local.poolend
    ipid           = local.ipid
    master_details = indent(8, yamlencode(local.master_details))
    worker_details = indent(8, yamlencode(local.worker_details))
    public_key     = tls_private_key.global_key.public_key_openssh
    rh_username    = var.rh_username
    rh_password    = var.rh_password
  }
}

# Cloud-init configuration
data "template_cloudinit_config" "config" {
  gzip          = false
  base64_encode = false
  
  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.user_data.rendered
  }
}

# Template for network configuration
data "template_file" "network_config" {
  template = file("${path.module}/24.4/network_config_${var.ip_type}.cfg")
}

# Create Master VMs
resource "libvirt_domain" "masters" {
  count     = var.masters_number
  name      = local.master_details[count.index].name
  memory    = var.memoryMB
  vcpu      = var.cpu
  autostart = true
  qemu_agent = true

  disk {
    volume_id = libvirt_volume.os_image.id
  }

  network_interface {
    network_id     = libvirt_network.network.id
    mac            = local.master_details[count.index].mac
    addresses      = [local.master_details[count.index].ip]
    wait_for_lease = true
  }

  cloudinit = libvirt_cloudinit_disk.commoninit[count.index].id

  cpu {
    mode = "host-passthrough"
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
    autoport    = "true"
  }
}

# Create Worker VMs
resource "libvirt_domain" "workers" {
  count     = var.workers_number
  name      = local.worker_details[count.index].name
  memory    = var.memoryMB
  vcpu      = var.cpu
  autostart = true
  qemu_agent = true

  disk {
    volume_id = libvirt_volume.os_image.id
  }

  network_interface {
    network_id     = libvirt_network.network.id
    mac            = local.worker_details[count.index].mac
    addresses      = [local.worker_details[count.index].ip]
    wait_for_lease = true
  }

  cloudinit = libvirt_cloudinit_disk.commoninit[var.masters_number + count.index].id

  cpu {
    mode = "host-passthrough"
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
    autoport    = "true"
  }
}
