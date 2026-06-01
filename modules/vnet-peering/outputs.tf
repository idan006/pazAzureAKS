output "hub_to_spoke_id" {
  description = "Hub-to-spoke peering ID."
  value       = azurerm_virtual_network_peering.hub_to_spoke.id
}

output "spoke_to_hub_id" {
  description = "Spoke-to-hub peering ID."
  value       = azurerm_virtual_network_peering.spoke_to_hub.id
}
