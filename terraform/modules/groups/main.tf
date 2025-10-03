data "azurerm_resource_group" "rg" {
    name = azurerm_resource_group.rg.name
}

resource "azurerm_resource_group" "rg" {
  name     = "global-infra-group-${var.region}"
  location = var.region
}
