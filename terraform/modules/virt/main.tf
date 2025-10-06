locals {
    user = "azureuser"
    applicationRoleBastion = "bastion"
    applicationRoleLoadBalancer = "loadBalancer"
    applicationRoleKubernetes = "kubernetes"
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

  tags = { 
    "applicationRole" = local.applicationRoleBastion
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

  tags = { 
      "applicationRole" = local.applicationRoleLoadBalancer
   }
  
}

resource "azurerm_linux_virtual_machine_scale_set" "global_kubernetes_vm_scale_set" {
  name                = "global-kubernetes-vm-scale-set"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  sku                 = "Standard_B2als_v2"
  instances           = 3 # TODO 1x worker/control 2x worker (configure k0sctl.yaml)
  admin_username      = local.user

  admin_ssh_key {
    username   = local.user
    public_key = file("bastion.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "kubernetes_vm_net_interface"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = var.internal_subnet
    }
  }

  tags = { 
    "applicationRole" = local.applicationRoleKubernetes  
  }
}