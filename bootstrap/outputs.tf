output "resource_group_name" {
  description = "Remote state resource group name."
  value       = azurerm_resource_group.state.name
}

output "storage_account_name" {
  description = "Remote state storage account name."
  value       = azurerm_storage_account.state.name
}

output "container_name" {
  description = "Remote state blob container name."
  value       = azurerm_storage_container.state.name
}
