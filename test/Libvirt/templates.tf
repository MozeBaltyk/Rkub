data "template_cloudinit_config" "config" {
  for_each = { for vm in concat(local.master_details, local.worker_details) : vm.name => vm }

  gzip          = false
  base64_encode = false
  
  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/${local.cloud_init_version}/cloud_init.cfg.tftpl", {
      os_name        =   local.os_name
      hostname       =   each.value.name
      fqdn           =   "${each.value.name}.${local.subdomain}"
      domain         =   local.subdomain
      clusterid      =   var.clusterid
      timezone       =   var.timezone
      master_details =   indent(8, yamlencode(local.master_details))
      worker_details =   indent(8, yamlencode(local.worker_details))
      public_key     =   tls_private_key.global_key.public_key_openssh
      rh_username    =   var.rh_username
      rh_password    =   var.rh_password
    })
  }
}

data "template_file" "common_network_config" {
  template = file("${path.module}/${local.cloud_init_version}/network_config_${var.ip_type}.cfg")
}

# Use CloudInit ISO to add SSH key to the instances
resource "libvirt_cloudinit_disk" "commoninit" {
  for_each = { for vm in concat(local.master_details, local.worker_details) : vm.name => vm }

  name           = "${each.value.name}-commoninit.iso"
  pool           = var.pool
  user_data      = data.template_cloudinit_config.config[each.key].rendered
  network_config = data.template_file.common_network_config.rendered
}
