data "azurerm_resource_group" "mealops" {
  name = var.resource_group_name
}

resource "azurerm_container_registry" "mealops" {
  name                = var.acr_name
  resource_group_name = data.azurerm_resource_group.mealops.name
  location            = data.azurerm_resource_group.mealops.location
  sku           = "Standard"
  admin_enabled = false
}