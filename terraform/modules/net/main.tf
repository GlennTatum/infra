locals {
  name = "${var.resource_group_name}-net"
  bastion_ip = "172.16.1.15"
  load_balancer_ip = "172.16.1.12"
}

resource "azurerm_virtual_network" "global_vnet" {
  name = "${local.name}-vnet"
  resource_group_name = var.resource_group_name
  location = var.resource_group_location
  address_space = ["172.16.0.0/16"]
}

output "private_subnet_internal" {
  value = azurerm_subnet.global_subnet_internal.id
}

resource "azurerm_subnet" "global_subnet_internal" {
  name = "${local.name}-subnet-internal"
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.global_vnet.name
  address_prefixes = ["172.16.1.0/24"]
}

resource "azurerm_nat_gateway" "global_nat_gateway" {
  name = "${local.name}-nat-gateway"
  resource_group_name = var.resource_group_name
  location = var.resource_group_location
  sku_name = "Standard"
}

########## NAT GATEWAY ##########

resource "azurerm_public_ip" "global_nat_gateway_public_ip" {
  name = "${local.name}-nat-gateway-public-ip"
  resource_group_name = var.resource_group_name
  location = var.resource_group_location
  allocation_method = "Static"
  sku = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "global_nat_gateway_public_ip_association" {
  nat_gateway_id = azurerm_nat_gateway.global_nat_gateway.id
  public_ip_address_id = azurerm_public_ip.global_nat_gateway_public_ip.id
}

resource "azurerm_subnet_nat_gateway_association" "global_nat_gateway_subnet" {
  subnet_id = azurerm_subnet.global_subnet_internal.id
  nat_gateway_id = azurerm_nat_gateway.global_nat_gateway.id
}

########## NAT GATEWAY ##########

########## BASTION HOST ##########

resource "azurerm_public_ip" "global_bastion_public_ip" {
  name = "${local.name}-bastion-public-ip"
  resource_group_name = var.resource_group_name
  location = var.resource_group_location
  allocation_method = "Static"
}

output "bastion_nic_id" {
  value = azurerm_network_interface.global_bastion_nic.id
}

resource "azurerm_network_interface" "global_bastion_nic" {
  name = "${local.name}-bastion-nic"
  resource_group_name = var.resource_group_name
  location = var.resource_group_location
  
  ip_configuration {
    name = "bastion-nic"
    subnet_id = azurerm_subnet.global_subnet_internal.id
    public_ip_address_id = azurerm_public_ip.global_bastion_public_ip.id
    private_ip_address_allocation = "Static"
    private_ip_address = local.bastion_ip
  }
}

# allow internet traffic to traverse into the bastion nsg and allow it to ssh within the subnet
# internet -> bastion_nsg -> vnet_nsg -> bastion -> internal vnet hosts
resource "azurerm_network_security_group" "global_bastion_security_group" {
  name = "global-bastion-security-group"
  resource_group_name = var.resource_group_name
  location = var.resource_group_location

  security_rule {
    name = "AllowInboundSSHFromInternet"
    priority = 105
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = 22
    source_address_prefix = "Internet"
    destination_address_prefix = local.bastion_ip
  }
}

resource "azurerm_network_interface_security_group_association" "bastion_nic_to_nsg" {
  network_interface_id = azurerm_network_interface.global_bastion_nic.id
  network_security_group_id = azurerm_network_security_group.global_bastion_security_group.id
}

########## BASTION HOST ##########

########## PRIVATE VNET SECURITY RULES ##########

resource "azurerm_network_security_group" "global_vnet_security_group" {
  name = "global-vnet-security-group"
  resource_group_name = var.resource_group_name
  location = var.resource_group_location

  security_rule {
    name = "AllowInboundSSHFromInternetToBastionVNETHost"
    priority = 105
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = 22
    source_address_prefix = "Internet"
    destination_address_prefix = local.bastion_ip
  }

  security_rule {
    name = "AllowInboundSSHFromInternetToLoadBalancerVNETHost"
    priority = 106
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = 22
    source_address_prefix = "Internet"
    destination_address_prefix = local.load_balancer_ip
  }

  security_rule {
    name = "AllowHTTPFromInternetToLoadBalancerVNETHost"
    priority = 120
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = 80
    source_address_prefix = "Internet"
    destination_address_prefix = local.load_balancer_ip
  }

  security_rule {
    name = "AllowHTTPSFromInternetToLoadBalancerVNETHost"
    priority = 130
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = 443
    source_address_prefix = "Internet"
    destination_address_prefix = local.load_balancer_ip
  }
}

resource "azurerm_subnet_network_security_group_association" "global_vnet_to_nsg" {
  network_security_group_id = azurerm_network_security_group.global_vnet_security_group.id
  subnet_id = azurerm_subnet.global_subnet_internal.id
}

########## PRIVATE VNET SECURITY RULES ##########

########## LOAD BALANCER ##########


# public ip, nic, nsg (443, 80), nsg (vnet, 443, 80)

resource "azurerm_public_ip" "global_load_balancer_public_ip" {
  name = "${local.name}-load-balancer-public-ip"
  resource_group_name = var.resource_group_name
  location = var.resource_group_location
  allocation_method = "Static"
}

output "load_balancer_nic_id" {
  value = azurerm_network_interface.global_load_balancer_nic.id
}

resource "azurerm_network_interface" "global_load_balancer_nic" {
  name = "${local.name}-load-balancer-nic"
  resource_group_name = var.resource_group_name
  location = var.resource_group_location
  
  ip_configuration {
    name = "load-balancer-nic"
    subnet_id = azurerm_subnet.global_subnet_internal.id
    public_ip_address_id = azurerm_public_ip.global_load_balancer_public_ip.id
    private_ip_address_allocation = "Static"
    private_ip_address = local.load_balancer_ip
  }
}

resource "azurerm_network_security_group" "global_load_balancer_security_group" {
  name = "global-load-balancer-security-group"
  resource_group_name = var.resource_group_name
  location = var.resource_group_location


  security_rule {
    name = "AllowInboundSSHFromInternet"
    priority = 106
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = 22
    source_address_prefix = "Internet"
    destination_address_prefix = local.load_balancer_ip
  }

  security_rule {
    name = "AllowHTTPFromInternet"
    priority = 120
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = 80
    source_address_prefix = "Internet"
    destination_address_prefix = local.load_balancer_ip
  }

  security_rule {
    name = "AllowHTTPSFromInternet"
    priority = 130
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = 443
    source_address_prefix = "Internet"
    destination_address_prefix = local.load_balancer_ip
  }
}

resource "azurerm_network_interface_security_group_association" "load_balancer_nic_to_nsg" {
  network_interface_id = azurerm_network_interface.global_load_balancer_nic.id
  network_security_group_id = azurerm_network_security_group.global_load_balancer_security_group.id
}

########## LOAD BALANCER ##########