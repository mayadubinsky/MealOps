output "resource_group_name" {
  description = "Name of the Terraform backend resource group"
  value       = azurerm_resource_group.main.name
}

output "storage_account_name" {
  description = "Name of the Terraform backend storage account"
  value       = azurerm_storage_account.tfstate.name
}

output "container_name" {
  description = "Name of the Terraform state container"
  value       = azurerm_storage_container.tfstate.name
}
