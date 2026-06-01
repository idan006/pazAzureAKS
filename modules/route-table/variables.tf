variable "name" {
  description = "Route table name."
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

variable "firewall_private_ip_address" {
  description = "Azure Firewall private IP next hop."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs associated to this route table."
  type        = list(string)
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
