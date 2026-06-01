output "id" {
  description = "Route table ID."
  value       = azurerm_route_table.this.id
}

output "name" {
  description = "Route table name."
  value       = azurerm_route_table.this.name
}
