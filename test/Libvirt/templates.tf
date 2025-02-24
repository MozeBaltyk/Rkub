# Generate individual Cloud-init templates for each master and worker
resource "local_file" "vm_cloud_init_template" {
  for_each = { for vm in concat(local.master_details, local.worker_details) : vm.name => vm }

  filename = "${path.module}/24.4/cloud_init_${each.key}.cfg.tftpl"

  content  = templatefile("${path.module}/24.4/cloud_init.cfg.tftpl", {
    timezone         = var.timezone
    hostname         = each.value.name
    fqdn             = "${each.value.name}.${local.subdomain}"
    public_key       = tls_private_key.global_key.public_key_openssh
    gateway_ip       = local.gateway_ip
    broadcast_ip     = local.broadcast_ip
    netmask          = local.netmask
    poolstart        = local.poolstart
    poolend          = local.poolend
    ipid             = local.ipid
    master_details   = local.master_details
    worker_details   = local.worker_details
    domain           = local.domain
    rh_username      = var.rh_username
    rh_password      = var.rh_password
    os_name          = local.os_name
    # Add other variables as needed
  })
}
