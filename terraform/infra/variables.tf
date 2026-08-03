variable "resource_group_name" {
  description = "Resource group containing the Terraform backend"
  type        = string
}

variable "location" {
  description = "Azure region for the backend resources"
  type        = string
}

variable "storage_account_name" {
  description = "Storage account used for Terraform remote state"
  type        = string
}

variable "container_name" {
  description = "Blob container used for Terraform remote state"
  type        = string
}

variable "acr_name" {
  description = "Azure Container Registery name"
  type        = string
}