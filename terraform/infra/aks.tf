resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  location            = data.azurerm_resource_group.mealops.location
  resource_group_name = data.azurerm_resource_group.mealops.name
  dns_prefix          = "mealops"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = var.aks_vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  sku_tier = "Free"
}