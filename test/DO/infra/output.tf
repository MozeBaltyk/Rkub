###
### Generate the hosts.ini file
###
resource "local_file" "ansible_inventory" {
  content = templatefile("../../inventory/hosts.tpl",
    {
     controller_ips = digitalocean_droplet.controllers[*].ipv4_address,
     worker_ips     = digitalocean_droplet.workers[*].ipv4_address
    }
  )
  filename = "../../inventory/hosts.ini"
}

###
### Display
###
output "ip_address_controllers" {
  value = digitalocean_droplet.controllers[*].ipv4_address
  description = "The public IP address of your rke2 controllers."
}

output "ip_address_workers" {
  value = digitalocean_droplet.workers[*].ipv4_address
  description = "The public IP address of your rke2 workers."
}
