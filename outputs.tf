output "resource_group_name" {
  description = "Environment resource group name."
  value       = module.resource_group.name
}

output "hub_vnet_id" {
  description = "Hub VNet ID."
  value       = module.hub_network.id
}

output "spoke_vnet_id" {
  description = "Spoke VNet ID."
  value       = module.spoke_network.id
}

output "aks_cluster_name" {
  description = "Private AKS cluster name."
  value       = module.aks.name
}

output "aks_private_fqdn" {
  description = "Private AKS API FQDN."
  value       = module.aks.private_fqdn
}

output "application_gateway_public_ip" {
  description = "The only default public IP in the platform."
  value       = module.application_gateway.public_ip_address
}

output "firewall_private_ip" {
  description = "Azure Firewall private IP used as the UDR next hop."
  value       = module.firewall.private_ip_address
}

output "key_vault_uri" {
  description = "Key Vault URI for future CSI/workload identity integrations."
  value       = module.key_vault.vault_uri
}
