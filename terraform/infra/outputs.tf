output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.mealops.name
}

output "acr_login_server" {
  description = "Login server of the Azure Container Registry"
  value       = azurerm_container_registry.mealops.login_server
}