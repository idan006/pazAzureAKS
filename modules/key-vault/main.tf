data "azurerm_client_config" "current" {}

locals {
  admin_object_ids = var.assign_current_principal_admin ? distinct(concat(var.admin_object_ids, [data.azurerm_client_config.current.object_id])) : var.admin_object_ids
}

resource "azurerm_key_vault" "this" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = var.sku_name
  rbac_authorization_enabled    = true
  purge_protection_enabled      = true
  soft_delete_retention_days    = var.soft_delete_retention_days
  public_network_access_enabled = false
  tags                          = var.tags

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
  }
}

resource "azurerm_private_dns_zone" "this" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  name                  = "${var.name}-vault-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = var.private_dns_zone_vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_endpoint" "this" {
  name                = "${var.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.name}-kv-psc"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "vault"
    private_dns_zone_ids = [azurerm_private_dns_zone.this.id]
  }

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.this
  ]
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  name                       = "${var.name}-diagnostics"
  target_resource_id         = azurerm_key_vault.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_role_assignment" "key_vault_admin" {
  for_each = toset(local.admin_object_ids)

  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "secrets_user" {
  for_each = toset(var.secrets_user_object_ids)

  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value
}
