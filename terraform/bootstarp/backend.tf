terraform {
  backend "azurerm" {
    resource_group_name  = "mealops-rg-v2"
    storage_account_name = "mealopstfstate12345"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
