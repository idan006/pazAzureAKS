variable "hub_to_spoke_name" {
  description = "Hub-to-spoke peering name."
  type        = string
}

variable "spoke_to_hub_name" {
  description = "Spoke-to-hub peering name."
  type        = string
}

variable "hub_resource_group" {
  description = "Hub VNet resource group."
  type        = string
}

variable "spoke_resource_group" {
  description = "Spoke VNet resource group."
  type        = string
}

variable "hub_vnet_name" {
  description = "Hub VNet name."
  type        = string
}

variable "spoke_vnet_name" {
  description = "Spoke VNet name."
  type        = string
}

variable "hub_vnet_id" {
  description = "Hub VNet ID."
  type        = string
}

variable "spoke_vnet_id" {
  description = "Spoke VNet ID."
  type        = string
}
