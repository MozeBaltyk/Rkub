###
### Generate the hosts.ini file
###
resource "local_file" "ansible_inventory" {
  content = templatefile("../inventory/hosts.tpl",
    {
      controller_ips = libvirt_domain.masters[*].network_interface[0].addresses[0],
      worker_ips     = try([for w in libvirt_domain.workers : w.network_interface[0].addresses[0]], []),
      master_details = local.master_details,
      worker_details = local.worker_details,
    }
  )
  filename = "../inventory/hosts.ini"

  depends_on = [
    libvirt_domain.masters,
    libvirt_domain.workers
  ]
}

output "master_ips" {
  description = "The IP addresses of the master VMs."
  value       = libvirt_domain.masters[*].network_interface[0].addresses
}

output "worker_ips" {
  description = "The IP addresses of the worker VMs."
  value       = try([for w in libvirt_domain.workers : w.network_interface[0].addresses[0]], [])
}

# output "rendered_cloud_init" {
#   value = data.template_file.user_data.rendered
# }
