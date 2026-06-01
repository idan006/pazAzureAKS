variable "name" {
  description = "Azure Firewall name."
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

variable "subnet_id" {
  description = "AzureFirewallSubnet ID."
  type        = string
}

variable "public_ip_enabled" {
  description = "Whether to create and attach a public IP to Azure Firewall."
  type        = bool
  default     = false
}

variable "source_cidrs" {
  description = "CIDRs allowed through the baseline firewall egress rules."
  type        = list(string)
}

variable "sku_name" {
  description = "Azure Firewall SKU name."
  type        = string
  default     = "AZFW_VNet"
}

variable "sku_tier" {
  description = "Azure Firewall SKU tier."
  type        = string
  default     = "Standard"
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
