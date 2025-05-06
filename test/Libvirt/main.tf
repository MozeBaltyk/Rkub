### Pool
resource "libvirt_pool" "rkub_pool" {
  name = var.pool
  type = "dir"
  target {
    path = local.rkub_pool_path
  }
  xml { 
    xslt = file("${path.module}/files/os_pool_permissions.xsl.tpl" ) 
  }
}


### Disks
# Fetch the OS image from local storage
resource "libvirt_volume" "os_image" {
  name   = "${var.selected_version}-os_image"
  pool   = libvirt_pool.rkub_pool.name
  source = local.qcow2_image
  format = "qcow2"
}

resource "libvirt_volume" "resized_os_image" {
  for_each = { for vm in concat(local.master_details, local.worker_details) : vm.name => vm }
  name     = "${each.value.name}-disk-${var.product}-${var.release_version}.qcow2"
  base_volume_id = libvirt_volume.os_image.id
  pool     = libvirt_pool.rkub_pool.name
  size     = 10 * 1024 * 1024 * 1024  # 10 GB in bytes
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
  memory    = var.memory_size
  vcpu      = var.cpu_size
  autostart = true
  qemu_agent = true

  disk {
    volume_id = libvirt_volume.resized_os_image[local.master_details[count.index].name].id
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
  memory    = var.memory_size
  vcpu      = var.cpu_size
  autostart = true
  qemu_agent = true

  disk {
    volume_id = libvirt_volume.resized_os_image[local.worker_details[count.index].name].id
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
