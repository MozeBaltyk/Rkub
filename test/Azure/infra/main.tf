# Azure Infrastructure Resources

###
### SSH
###

# Generate an SSH key pair
resource "tls_private_key" "global_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save the public key to a local file
resource "local_file" "ssh_public_key_openssh" {
  filename = "${path.module}/.key.pub"
  content  = tls_private_key.global_key.public_key_openssh
}

# Save the private key to a local file
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
resource "azurerm_virtual_network" "rkub-project-network" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rkub-project.location
  resource_group_name = azurerm_resource_group.rkub-project.name

  tags = {
    Creator = "rkub-${var.GITHUB_RUN_ID}"
  }
}

resource "time_sleep" "wait_for_vpc" {
  depends_on = [azurerm_virtual_network.rkub-project-network]
  destroy_duration = "100s" # Adjust duration as needed
  create_duration = "20s"  # Adjust duration as needed
}
resource "null_resource" "placeholder" {
  depends_on = [time_sleep.wait_for_vpc]
}

# Azure internal subnet
resource "azurerm_subnet" "rkub-project-internal" {
  name                 = "rkub-project-internal"
  resource_group_name  = azurerm_resource_group.rkub-project.name
  virtual_network_name = azurerm_virtual_network.rkub-project-network.name
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


# Network Security Group
resource "azurerm_network_security_group" "rkub-project-nsg" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.rkub-project.location
  resource_group_name = azurerm_resource_group.rkub-project.name

  security_rule {
    name                       = "Allow_6443"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_SSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Creator = "rkub-${var.GITHUB_RUN_ID}"
  }
}

# Associate NSG with Subnet
resource "azurerm_subnet_network_security_group_association" "rkub-project-subnet-nsg-association" {
  subnet_id                 = azurerm_subnet.rkub-project-internal.id
  network_security_group_id = azurerm_network_security_group.rkub-project-nsg.id
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

  depends_on = [null_resource.placeholder, azurerm_public_ip.controller-pip, azurerm_network_interface.controller-interfaces]
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

  depends_on = [null_resource.placeholder, azurerm_public_ip.worker-pip, azurerm_network_interface.worker-interfaces]
}
