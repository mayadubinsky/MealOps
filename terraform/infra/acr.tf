data "azurerm_container_registry" "mealops" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
}