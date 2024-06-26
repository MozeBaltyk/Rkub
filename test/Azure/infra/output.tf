###
### Generate the hosts.ini file
###
resource "local_file" "ansible_inventory" {
  content = templatefile("../../inventory/hosts.tpl",
    {
     controller_ips = azurerm_public_ip.controller-pip[*].ip_address,
     worker_ips     = azurerm_public_ip.worker-pip[*].ip_address
    }
  )
  filename = "../../inventory/hosts.ini"
  depends_on = [null_resource.placeholder, azurerm_linux_virtual_machine.workers, azurerm_linux_virtual_machine.controllers]
}

###
### Display
###

output "ip_address_controllers" {
  value = azurerm_public_ip.controller-pip[*].ip_address
  description = "The public IP address of your rke2 controllers."
  depends_on = [null_resource.placeholder, azurerm_linux_virtual_machine.controllers]
}

output "ip_address_workers" {
  value = azurerm_public_ip.worker-pip[*].ip_address
  description = "The public IP address of your rke2 workers."
  depends_on = [null_resource.placeholder, azurerm_linux_virtual_machine.workers]
}