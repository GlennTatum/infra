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



module "groups" {
    source = "./modules/groups"
}

module "net" {
    source = "./modules/net"
    resource_group_id = module.groups.azurerm_resource_group.id
    resource_group_location = module.groups.azurerm_resource_group.location
    resource_group_name = module.groups.azurerm_resource_group.name
}

module "virt" {
    source = "./modules/virt"
    resource_group_id = module.groups.azurerm_resource_group.id
    resource_group_location = module.groups.azurerm_resource_group.location
    resource_group_name = module.groups.azurerm_resource_group.name
    internal_subnet = module.net.private_subnet_internal
    bastion_nic = module.net.bastion_nic_id
    load_balancer_nic = module.net.load_balancer_nic_id
}
