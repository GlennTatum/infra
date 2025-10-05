locals {
    user = "azureuser"
}

resource "azurerm_linux_virtual_machine" "global_bastion_vm" {
  name                = "global-bastion-vm"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  size                = "Standard_B2ats_v2"
  admin_username      = local.user
  network_interface_ids = [
    var.bastion_nic
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_ed25519.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb = 32
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  
}

resource "azurerm_linux_virtual_machine" "global_load_balancer_vm" {
  name                = "global-load-balancer-vm"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  size                = "Standard_B2ats_v2"
  admin_username      = local.user
  network_interface_ids = [
    var.load_balancer_nic
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_ed25519.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb = 32
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  
}