variable "name" {
  description = "AKS cluster name."
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

variable "dns_prefix" {
  description = "AKS DNS prefix."
  type        = string
}

variable "kubernetes_version" {
  description = "Optional Kubernetes version."
  type        = string
  default     = null
}

variable "node_count" {
  description = "Default node count."
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "Default node VM size."
  type        = string
  default     = "Standard_D4s_v5"
}

variable "availability_zones" {
  description = "Node pool availability zones."
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "max_pods" {
  description = "Maximum pods per node."
  type        = number
  default     = 30
}

variable "os_disk_size_gb" {
  description = "OS disk size for the default node pool."
  type        = number
  default     = 128
}

variable "subnet_id" {
  description = "AKS subnet ID."
  type        = string
}

variable "service_cidr" {
  description = "AKS service CIDR."
  type        = string
}

variable "dns_service_ip" {
  description = "AKS DNS service IP."
  type        = string
}

variable "admin_group_object_ids" {
  description = "Optional Entra ID admin group object IDs."
  type        = list(string)
  default     = []
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID."
  type        = string
}

variable "azure_policy_enabled" {
  description = "Enable Azure Policy add-on for AKS."
  type        = bool
  default     = true
}

variable "oidc_issuer_enabled" {
  description = "Enable the AKS OIDC issuer for workload identity."
  type        = bool
  default     = true
}

variable "workload_identity_enabled" {
  description = "Enable AKS workload identity."
  type        = bool
  default     = true
}

variable "local_account_disabled" {
  description = "Disable local admin account access."
  type        = bool
  default     = false
}

variable "sku_tier" {
  description = "AKS SKU tier."
  type        = string
  default     = "Free"
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
