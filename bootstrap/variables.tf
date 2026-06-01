variable "subscription_id" {
  description = "Azure subscription ID. Prefer ARM_SUBSCRIPTION_ID in CI/CD if this is left null."
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region for the Terraform state resources."
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Resource group for Terraform remote state."
  type        = string
  default     = "rg-tfstate-azure-hub-spoke-aks"
}

variable "storage_account_name" {
  description = "Globally unique storage account name for Terraform state."
  type        = string
}

variable "container_name" {
  description = "Blob container name for Terraform state."
  type        = string
  default     = "tfstate"
}

variable "tags" {
  description = "Tags for bootstrap resources."
  type        = map(string)
  default = {
    managed_by = "terraform"
    project    = "azure-hub-spoke-aks"
    workload   = "remote-state"
  }
}
