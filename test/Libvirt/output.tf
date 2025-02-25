###
### Generate the hosts.ini file
###

output "master_ips" {
  description = "The IP addresses of the master VMs."
  value       = flatten([for m in libvirt_domain.masters : m.network_interface[0].addresses])
}

output "worker_ips" {
  description = "The IP addresses of the worker VMs."
  value       = flatten([for w in libvirt_domain.workers : w.network_interface[0].addresses])
}
