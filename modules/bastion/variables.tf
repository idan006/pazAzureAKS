variable "name" {
  description = "Azure Bastion name."
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
  description = "AzureBastionSubnet ID."
  type        = string
}

variable "public_ip_enabled" {
  description = "Whether to create and attach a public IP to Bastion."
  type        = bool
  default     = false
}

variable "sku" {
  description = "Bastion SKU. Premium supports private-only designs where available."
  type        = string
  default     = "Premium"
}

variable "scale_units" {
  description = "Bastion scale units."
  type        = number
  default     = 2
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
