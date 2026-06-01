output "id" {
  description = "Application Gateway ID."
  value       = azurerm_application_gateway.this.id
}

output "name" {
  description = "Application Gateway name."
  value       = azurerm_application_gateway.this.name
}

output "public_ip_address" {
  description = "Application Gateway public IP address."
  value       = azurerm_public_ip.this.ip_address
}

output "public_ip_id" {
  description = "Application Gateway public IP resource ID."
  value       = azurerm_public_ip.this.id
}
