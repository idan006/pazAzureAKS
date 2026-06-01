output "id" {
  description = "Spoke VNet ID."
  value       = azurerm_virtual_network.this.id
}

output "name" {
  description = "Spoke VNet name."
  value       = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  description = "Spoke subnet IDs keyed by subnet name."
  value       = { for name, subnet in azurerm_subnet.this : name => subnet.id }
}

output "network_security_group_ids" {
  description = "Spoke NSG IDs keyed by subnet name."
  value       = { for name, nsg in azurerm_network_security_group.this : name => nsg.id }
}

output "aks_subnet_id" {
  description = "AKS subnet ID."
  value       = azurerm_subnet.this["aks-subnet"].id
}

output "app_subnet_id" {
  description = "Application workload subnet ID."
  value       = azurerm_subnet.this["app-subnet"].id
}

output "private_endpoint_subnet_id" {
  description = "Private endpoint subnet ID."
  value       = azurerm_subnet.this["private-endpoint-subnet"].id
}
