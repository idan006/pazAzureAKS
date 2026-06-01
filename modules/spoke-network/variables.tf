variable "name" {
  description = "Spoke VNet name."
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
  description = "Spoke VNet address space."
  type        = list(string)
}

variable "subnets" {
  description = "Spoke subnet map keyed by subnet name."
  type = map(object({
    address_prefixes = list(string)
  }))
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
