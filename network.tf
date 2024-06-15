
resource "azurerm_virtual_network" "main" {
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  name                = "${local.resource_prefix}-vnet"
  resource_group_name = azurerm_resource_group.main.name

}


resource "azurerm_subnet" "aca" {
  address_prefixes     = ["10.0.0.0/21"]
  name                 = "${local.resource_prefix}-aca-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name

}

resource "azurerm_nat_gateway" "aca" {
  location            = azurerm_resource_group.main.location
  name                = "${local.resource_prefix}-aca-nat"
  resource_group_name = azurerm_resource_group.main.name


}

resource "azurerm_public_ip" "natg" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.main.location
  name                = "${local.resource_prefix}-natg-public-ip"
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"

}

resource "azurerm_nat_gateway_public_ip_association" "natg" {
  nat_gateway_id       = azurerm_nat_gateway.aca.id
  public_ip_address_id = azurerm_public_ip.natg.id

}

resource "azurerm_subnet_nat_gateway_association" "natg" {
  nat_gateway_id = azurerm_nat_gateway.aca.id
  subnet_id      = azurerm_subnet.aca.id

}
