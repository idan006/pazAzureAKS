variable "subscription_id" {
  description = "Azure subscription ID. Prefer ARM_SUBSCRIPTION_ID in CI/CD if this is left null."
  type        = string
  default     = null
}

variable "project_name" {
  description = "Project prefix used for resource naming."
  type        = string
  default     = "azure-hub-spoke-aks"
}

variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "environment must be one of dev, qa, or prod."
  }
}

variable "location" {
  description = "Azure region for the environment."
  type        = string
}

variable "tags" {
  description = "Required resource tags."
  type        = map(string)
  default     = {}
}

variable "hub_address_space" {
  description = "Hub VNet address space."
  type        = list(string)
}

variable "hub_subnets" {
  description = "Hub subnet definitions keyed by subnet name."
  type = map(object({
    address_prefixes = list(string)
  }))
}

variable "spoke_address_space" {
  description = "Environment spoke VNet address space."
  type        = list(string)
}

variable "spoke_subnets" {
  description = "Spoke subnet definitions keyed by subnet name."
  type = map(object({
    address_prefixes = list(string)
  }))
}

variable "aks_kubernetes_version" {
  description = "Optional AKS Kubernetes version. Leave null to use the Azure default."
  type        = string
  default     = null
}

variable "aks_node_count" {
  description = "Default AKS system node pool count."
  type        = number
  default     = 2
}

variable "aks_vm_size" {
  description = "Default AKS system node pool VM size."
  type        = string
  default     = "Standard_D4s_v5"
}

variable "aks_service_cidr" {
  description = "AKS service CIDR."
  type        = string
  default     = "172.16.0.0/16"
}

variable "aks_dns_service_ip" {
  description = "AKS DNS service IP from the service CIDR."
  type        = string
  default     = "172.16.0.10"
}

variable "aks_admin_group_object_ids" {
  description = "Optional Entra ID group object IDs for AKS admin access."
  type        = list(string)
  default     = []
}

variable "aks_availability_zones" {
  description = "Availability zones for the default AKS node pool."
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "nginx_ingress_private_ip" {
  description = "Static private IP assigned to the internal nginx ingress LoadBalancer service."
  type        = string
}

variable "app_gateway_backend_fqdns" {
  description = "Optional backend FQDNs for Application Gateway."
  type        = list(string)
  default     = []
}

variable "app_gateway_host_names" {
  description = "Optional host names for the Application Gateway HTTP listener."
  type        = list(string)
  default     = []
}

variable "firewall_public_ip_enabled" {
  description = "Enable only if your Azure Firewall SKU/egress design requires a public IP; false keeps the one-public-IP architecture."
  type        = bool
  default     = false
}

variable "bastion_public_ip_enabled" {
  description = "Enable only if private-only Bastion is unavailable in your region/SKU; false keeps the one-public-IP architecture."
  type        = bool
  default     = false
}

variable "key_vault_soft_delete_retention_days" {
  description = "Key Vault soft-delete retention period."
  type        = number
  default     = 90
}

variable "key_vault_admin_object_ids" {
  description = "Principal object IDs assigned Key Vault Administrator."
  type        = list(string)
  default     = []
}

variable "key_vault_secrets_user_object_ids" {
  description = "Principal object IDs assigned Key Vault Secrets User."
  type        = list(string)
  default     = []
}

variable "key_vault_assign_current_principal_admin" {
  description = "Assign the current deployer Key Vault Administrator for bootstrap operations."
  type        = bool
  default     = true
}
