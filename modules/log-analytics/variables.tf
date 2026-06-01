variable "name" {
  description = "Log Analytics workspace name."
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

variable "sku" {
  description = "Log Analytics SKU."
  type        = string
  default     = "PerGB2018"
}

variable "retention_in_days" {
  description = "Retention in days."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
