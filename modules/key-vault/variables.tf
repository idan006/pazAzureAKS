variable "name" {
  description = "Key Vault name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "sku_name" {
  description = "Key Vault SKU."
  type        = string
  default     = "standard"
}

variable "soft_delete_retention_days" {
  description = "Soft-delete retention days."
  type        = number
  default     = 90
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for the Key Vault private endpoint."
  type        = string
}

variable "private_dns_zone_vnet_id" {
  description = "VNet ID linked to the Key Vault private DNS zone."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for Key Vault diagnostic logs."
  type        = string
}

variable "admin_object_ids" {
  description = "Principal object IDs assigned Key Vault Administrator."
  type        = list(string)
  default     = []
}

variable "secrets_user_object_ids" {
  description = "Principal object IDs assigned Key Vault Secrets User."
  type        = list(string)
  default     = []
}

variable "assign_current_principal_admin" {
  description = "Assign the current deployer Key Vault Administrator for bootstrap operations."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
