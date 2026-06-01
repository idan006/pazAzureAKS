variable "environment" {
  description = "Environment name."
  type        = string
}

variable "resource_group_id" {
  description = "Environment resource group ID."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID."
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault ID."
  type        = string
}

variable "aks_cluster_id" {
  description = "AKS cluster ID."
  type        = string
}

variable "policy_assignment_enabled" {
  description = "Placeholder switch for future Azure Policy assignments."
  type        = bool
  default     = false
}

variable "defender_assignment_enabled" {
  description = "Placeholder switch for future Defender for Cloud configuration."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
