resource "azurerm_container_registry" "mealops" {
  name                = var.acr_name
  resource_group_name = data.azurerm_resource_group.mealops.name
  location            = data.azurerm_resource_group.mealops.location

  sku           = "Basic"
  admin_enabled = false
}