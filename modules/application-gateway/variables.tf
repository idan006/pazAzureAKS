variable "name" {
  description = "Application Gateway name."
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
  description = "ApplicationGatewaySubnet ID."
  type        = string
}

variable "backend_ip_addresses" {
  description = "Private backend IP addresses, normally the nginx internal LoadBalancer IP."
  type        = list(string)
}

variable "backend_fqdns" {
  description = "Optional backend FQDNs."
  type        = list(string)
  default     = []
}

variable "host_names" {
  description = "Optional listener host names."
  type        = list(string)
  default     = []
}

variable "capacity" {
  description = "Application Gateway WAF capacity."
  type        = number
  default     = 2
}

variable "waf_mode" {
  description = "WAF mode."
  type        = string
  default     = "Prevention"
}

variable "zones" {
  description = "Availability zones."
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
