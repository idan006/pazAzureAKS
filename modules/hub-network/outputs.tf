output "id" {
  description = "Hub VNet ID."
  value       = azurerm_virtual_network.this.id
}

output "name" {
  description = "Hub VNet name."
  value       = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  description = "Hub subnet IDs keyed by subnet name."
  value       = { for name, subnet in azurerm_subnet.this : name => subnet.id }
}

output "azure_firewall_subnet_id" {
  description = "AzureFirewallSubnet ID."
  value       = azurerm_subnet.this["AzureFirewallSubnet"].id
}

output "azure_bastion_subnet_id" {
  description = "AzureBastionSubnet ID."
  value       = azurerm_subnet.this["AzureBastionSubnet"].id
}

output "application_gateway_subnet_id" {
  description = "ApplicationGatewaySubnet ID."
  value       = azurerm_subnet.this["ApplicationGatewaySubnet"].id
}

output "shared_services_subnet_id" {
  description = "SharedServicesSubnet ID."
  value       = azurerm_subnet.this["SharedServicesSubnet"].id
}
