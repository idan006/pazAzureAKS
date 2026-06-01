variable "name" {
  description = "Hub VNet name."
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

variable "address_space" {
  description = "Hub VNet address space."
  type        = list(string)
}

variable "subnets" {
  description = "Hub subnet map keyed by subnet name."
  type = map(object({
    address_prefixes = list(string)
  }))
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
