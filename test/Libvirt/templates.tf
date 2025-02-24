data "template_file" "user_data" {
  template = file("${path.module}/${local.cloud_init_version}/cloud_init.cfg.tftpl")
  vars = {
    os_name    = local.os_name
    hostname   = var.hostname
    fqdn       = "${var.hostname}.${local.subdomain}"
    domain     = local.subdomain
    clusterid  = var.clusterid
    timezone   = var.timezone
    gateway_ip = local.gateway_ip
    broadcast_ip = local.broadcast_ip
    netmask = local.netmask
    network_cidr = var.network_cidr
    poolstart = local.poolstart
    poolend = local.poolend
    ipid = local.ipid
    master_details = indent(8, yamlencode(local.master_details))
    worker_details   = indent(8, yamlencode(local.worker_details))
    public_key = tls_private_key.global_key.public_key_openssh
    rh_username = var.rh_username
    rh_password = var.rh_password
  }
}

data "template_cloudinit_config" "config" {
  gzip          = false
  base64_encode = false
  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.user_data.rendered
  }
}

data "template_file" "network_config" {
  template = file("${path.module}/${local.cloud_init_version}/network_config_${var.ip_type}.cfg")
}

# Use CloudInit ISO to add SSH key to the instances
resource "libvirt_cloudinit_disk" "commoninit" {
  count          = var.masters_number + var.workers_number
  name           = "${var.hostname}-${var.selected_version}-commoninit-${count.index}.iso"
  pool           = var.pool
  user_data      = data.template_cloudinit_config.config.rendered
  network_config = data.template_file.network_config.rendered
}
