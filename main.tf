locals {
  resource_prefix = "ren-protocol"
}

resource "azurerm_resource_group" "main" {
  location = "francecentral"
  name     = "${local.resource_prefix}-rg"

}

resource "azurerm_log_analytics_workspace" "main" {
  location            = azurerm_resource_group.main.location
  name                = "${local.resource_prefix}-law"
  resource_group_name = azurerm_resource_group.main.name

}
