### Pool
resource "libvirt_pool" "rkub_pool" {
  name = var.pool
  type = "dir"
  target {
    path = local.rkub_pool_path
  }
}

# Fetch the OS image from local storage
resource "libvirt_volume" "os_image" {
  name   = "${var.selected_version}-os_image"
  pool   = libvirt_pool.rkub_pool.name
  source = local.qcow2_image
  format = "qcow2"
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
    wait_for_lease = true
  }

  cloudinit = libvirt_cloudinit_disk.commoninit[local.master_details[count.index].name].id

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
    wait_for_lease = true
  }

  cloudinit = libvirt_cloudinit_disk.commoninit[local.worker_details[count.index].name].id

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
