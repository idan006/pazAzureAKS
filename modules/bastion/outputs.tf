output "id" {
  description = "Azure Bastion ID."
  value       = azurerm_bastion_host.this.id
}

output "name" {
  description = "Azure Bastion name."
  value       = azurerm_bastion_host.this.name
}

output "public_ip_address" {
  description = "Azure Bastion public IP address when enabled."
  value       = var.public_ip_enabled ? azurerm_public_ip.this[0].ip_address : null
}
