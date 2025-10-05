output "azurerm_resource_group" {
  value = azurerm_resource_group.rg
}

resource "azurerm_resource_group" "rg" {
  name     = "node-infra-group-${var.region}"
  location = var.region
}
