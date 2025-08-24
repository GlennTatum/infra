terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.1.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {
    resource_group {
       prevent_deletion_if_contains_resources = false   
    }
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "infra-rg"
  location = "westus2"
}

resource "azurerm_virtual_network" "global_vnet" {
  name = "global-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  address_space = ["172.16.0.0/16"]
}

resource "azurerm_subnet" "global_subnet_internal" {
  name = "global-subnet-internal"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.global_vnet.name
  address_prefixes = ["172.16.1.0/24"]
}

resource "azurerm_public_ip" "global_bastion_public_ip" {
  name = "global-bastion-public-ip"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  allocation_method = "Static"
}

resource "azurerm_network_interface" "global_bastion_nic" {
  name = "global-bastion-nic"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  
  ip_configuration {
    name = "bastion-nic"
    subnet_id = azurerm_subnet.global_subnet_internal.id
    public_ip_address_id = azurerm_public_ip.global_bastion_public_ip.id
    private_ip_address_allocation = "Static"
    private_ip_address = "172.16.1.15"
  }
}

resource "azurerm_network_security_group" "global_bastion_security_group" {
  name = "global-bastion-security-group"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location

  security_rule {
    name = "AllowInboundSSHFromInternet"
    priority = 105
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = 22
    source_address_prefix = "Internet"
    destination_address_prefix = "172.16.1.15"
  }
}

resource "azurerm_network_security_group" "global_vnet_security_group" {
  name = "global-vnet-security-group"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location

  security_rule {
    name = "AllowInboundSSHFromInternet"
    priority = 110
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = 22
    source_address_prefix = "Internet"
    destination_address_prefix = "172.16.1.15"
  }
}

resource "azurerm_subnet_network_security_group_association" "global_vnet_to_nsg" {
  network_security_group_id = azurerm_network_security_group.global_vnet_security_group.id
  subnet_id = azurerm_subnet.global_subnet_internal.id
}

resource "azurerm_network_interface_security_group_association" "bastion_nic_to_nsg" {
  network_interface_id = azurerm_network_interface.global_bastion_nic.id
  network_security_group_id = azurerm_network_security_group.global_bastion_security_group.id
}

resource "azurerm_linux_virtual_machine" "global_bastion_vm" {
  name                = "global-bastion-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2ats_v2"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.global_bastion_nic.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_ed25519.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  
}

# resource "azurerm_linux_virtual_machine_scale_set" "global_kubernetes_agents" {
#   name = "kubernetes-agents-vms"
#   resource_group_name = azurerm_resource_group.rg.name
#   location = azurerm_resource_group.rg.location
#   priority = "Spot"
#   eviction_policy = "Deallocate" # Stop k0s with `k0s stop` on Preempt signal

#   instances = 3

#   sku = "Standard_E2as_v6"

#   admin_username = "azureuser"

#   admin_ssh_key {
#     username = "azureuser"
#     public_key = file("bastion.pub")
#   }

#   os_disk {
#     caching = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }

#   network_interface {
#     name = "kubernetes-agent-network-interface"
#     primary = true
#     ip_configuration {
#       name = "kubernetes-agent-internal-ip"
#       primary = true
#       subnet_id = azurerm_subnet.global_subnet_internal.id
      
#     }
#   }

#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "0001-com-ubuntu-server-jammy"
#     sku       = "22_04-lts-gen2"
#     version   = "latest"
#   }
# }
