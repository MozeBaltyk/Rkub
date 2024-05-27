# Azure Infrastructure Resources

###
### SSH
###
resource "tls_private_key" "global_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_public_key_openssh" {
  filename = "${path.module}/.key.pub"
  content  = tls_private_key.global_key.public_key_openssh
}

resource "local_sensitive_file" "ssh_private_key_pem" {
  filename        = "${path.module}/.key.private"
  content         = tls_private_key.global_key.private_key_pem
  file_permission = "0600"
}

###
### Project
###

# Resource group containing all resources
resource "azurerm_resource_group" "rkub-project" {
  name     = "${var.prefix}-rkub-${var.GITHUB_RUN_ID}"
  location = var.region

  tags = {
    Creator = "rkub-${var.GITHUB_RUN_ID}"
  }
}

###
### VPC
###

# Azure virtual network space
resource "azurerm_virtual_network" "rkub-project" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rkub-project.location
  resource_group_name = azurerm_resource_group.rkub-project.name

  tags = {
    Creator = "rkub-${var.GITHUB_RUN_ID}"
  }
}

# Azure internal subnet
resource "azurerm_subnet" "rkub-project-internal" {
  name                 = "rkub-project-internal"
  resource_group_name  = azurerm_resource_group.rkub-project.name
  virtual_network_name = azurerm_virtual_network.rkub-project.name
  address_prefixes     = ["10.0.0.0/16"]
}

### Controller

# Public IP for controller
resource "azurerm_public_ip" "controller-pip" {
  count               = var.controller_count
  name                = "controller-pip${count.index}"
  location            = azurerm_resource_group.rkub-project.location
  resource_group_name = azurerm_resource_group.rkub-project.name
  allocation_method   = "Dynamic"

  tags = {
    Creator = "rkub-${var.GITHUB_RUN_ID}"
  }
}

# Azure network interface
resource "azurerm_network_interface" "controller-interfaces" {
  count                = var.controller_count
  name                = "controller-interface${count.index}"
  location            = azurerm_resource_group.rkub-project.location
  resource_group_name = azurerm_resource_group.rkub-project.name

  ip_configuration {
    name                          = "controller_config"
    subnet_id                     = azurerm_subnet.rkub-project-internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.controller-pip[count.index].id
  }

  tags = {
    Creator = "rkub-${var.GITHUB_RUN_ID}"
  }
}

### Workers

# Public IP for workers
resource "azurerm_public_ip" "worker-pip" {
  count                = var.worker_count
  name                = "worker-pip${count.index}"
  location            = azurerm_resource_group.rkub-project.location
  resource_group_name = azurerm_resource_group.rkub-project.name
  allocation_method   = "Dynamic"

  tags = {
    Creator = "rkub-${var.GITHUB_RUN_ID}"
  }
}

# Azure network interface for workers
resource "azurerm_network_interface" "worker-interfaces" {
  count                = var.worker_count
  name                = "worker-interface${count.index}"
  location            = azurerm_resource_group.rkub-project.location
  resource_group_name = azurerm_resource_group.rkub-project.name

  ip_configuration {
    name                          = "worker_config"
    subnet_id                     = azurerm_subnet.rkub-project-internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.worker-pip[count.index].id
  }

  tags = {
    Creator = "rkub-${var.GITHUB_RUN_ID}"
  }
}


###
### Azure INSTANCES
###

# Azure linux virtual machine for creating a single node RKE cluster and installing the Rancher Server
resource "azurerm_linux_virtual_machine" "controllers" {
  count                 = var.controller_count
  name                  = "${var.prefix}-ctlr-${count.index}"
  location              = azurerm_resource_group.rkub-project.location
  resource_group_name   = azurerm_resource_group.rkub-project.name
  network_interface_ids = [azurerm_network_interface.controller-interfaces[count.index].id]
  size                  = var.instance_size
  admin_username        = var.node_username

  # Adding patch settings to avoid incompatibility
  patch_mode             = "ImageDefault"
  provision_vm_agent     = true

  source_image_reference {
    publisher = "Redhat"
    offer     = "RHEL"
    sku       = "9-lvm-gen2"
    version   = "latest"
  }

  admin_ssh_key {
    username   = var.node_username
    public_key = tls_private_key.global_key.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags = {
    Creator = "rkub-${var.GITHUB_RUN_ID}"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait > /dev/null",
      "echo 'Completed cloud-init!'",
    ]

    connection {
      type        = "ssh"
      host        = self.public_ip_address
      user        = var.node_username
      private_key = tls_private_key.global_key.private_key_pem
    }
  }

  depends_on = [azurerm_public_ip.controller-pip, azurerm_network_interface.controller-interfaces]
}

# Azure linux virtual machine for creating a single node RKE cluster and installing the Rancher Server
resource "azurerm_linux_virtual_machine" "workers" {
  count                 = var.worker_count
  name                  = "${var.prefix}-wkr-${count.index}"
  location              = azurerm_resource_group.rkub-project.location
  resource_group_name   = azurerm_resource_group.rkub-project.name
  network_interface_ids = [azurerm_network_interface.worker-interfaces[count.index].id]
  size                  = var.instance_size
  admin_username        = var.node_username

  # Adding patch settings to avoid incompatibility
  patch_mode             = "ImageDefault"
  provision_vm_agent     = true

  source_image_reference {
    publisher = "Redhat"
    offer     = "RHEL"
    sku       = "9-lvm-gen2"
    version   = "latest"
  }

  admin_ssh_key {
    username   = var.node_username
    public_key = tls_private_key.global_key.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags = {
    Creator = "rkub-${var.GITHUB_RUN_ID}"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait > /dev/null",
      "echo 'Completed cloud-init!'",
    ]

    connection {
      type        = "ssh"
      host        = self.public_ip_address
      user        = var.node_username
      private_key = tls_private_key.global_key.private_key_pem
    }
  }

  depends_on = [azurerm_public_ip.worker-pip, azurerm_network_interface.worker-interfaces]
}
