output "resource_group_name" {
  value = data.azurerm_resource_group.mealops.name
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "acr_login_server" {
  description = "Login server of the Azure Container Registry"
  value       = azurerm_container_registry.mealops.login_server
}