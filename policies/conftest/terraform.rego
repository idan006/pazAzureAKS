package terraform.azure

import rego.v1

deny contains msg if {
  some rc in input.resource_changes
  rc.type == "azurerm_public_ip"
  not contains(rc.address, "module.application_gateway")
  msg := sprintf("Only Application Gateway may create public IPs; found %s", [rc.address])
}

deny contains msg if {
  some rc in input.resource_changes
  rc.type == "azurerm_kubernetes_cluster"
  not rc.change.after.private_cluster_enabled
  msg := sprintf("AKS cluster %s must keep private_cluster_enabled=true", [rc.address])
}

deny contains msg if {
  some rc in input.resource_changes
  rc.type == "azurerm_kubernetes_cluster"
  pool := rc.change.after.default_node_pool[_]
  pool.node_public_ip_enabled
  msg := sprintf("AKS default node pool in %s must not enable node public IPs", [rc.address])
}

deny contains msg if {
  some rc in input.resource_changes
  rc.type == "azurerm_kubernetes_cluster"
  rc.change.after.network_profile[_].outbound_type != "userDefinedRouting"
  msg := sprintf("AKS cluster %s must route outbound traffic through UDR", [rc.address])
}

deny contains msg if {
  some rc in input.resource_changes
  rc.type == "azurerm_key_vault"
  rc.change.after.public_network_access_enabled
  msg := sprintf("Key Vault %s must disable public network access", [rc.address])
}

deny contains msg if {
  some rc in input.resource_changes
  rc.type == "azurerm_application_gateway"
  rc.change.after.sku[_].tier != "WAF_v2"
  msg := sprintf("Application Gateway %s must use WAF_v2", [rc.address])
}
