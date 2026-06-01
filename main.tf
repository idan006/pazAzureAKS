locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(var.tags, {
    environment = var.environment
    managed_by  = "terraform"
    project     = var.project_name
  })

  app_gateway_backend_addresses = [var.nginx_ingress_private_ip]
}

module "resource_group" {
  source = "./modules/resource-group"

  name     = "${local.name_prefix}-rg"
  location = var.location
  tags     = local.common_tags
}

module "log_analytics" {
  source = "./modules/log-analytics"

  name                = "${local.name_prefix}-law"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  retention_in_days   = var.environment == "prod" ? 90 : 30
  tags                = local.common_tags
}

module "hub_network" {
  source = "./modules/hub-network"

  name                = "${local.name_prefix}-hub-vnet"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  address_space       = var.hub_address_space
  subnets             = var.hub_subnets
  tags                = local.common_tags
}

module "spoke_network" {
  source = "./modules/spoke-network"

  name                = "${local.name_prefix}-spoke-vnet"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  address_space       = var.spoke_address_space
  subnets             = var.spoke_subnets
  tags                = local.common_tags
}

module "firewall" {
  source = "./modules/firewall"

  name                = "${local.name_prefix}-afw"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  subnet_id           = module.hub_network.azure_firewall_subnet_id
  public_ip_enabled   = var.firewall_public_ip_enabled
  source_cidrs        = var.spoke_address_space
  tags                = local.common_tags
}

module "route_table" {
  source = "./modules/route-table"

  name                        = "${local.name_prefix}-aks-udr"
  location                    = module.resource_group.location
  resource_group_name         = module.resource_group.name
  firewall_private_ip_address = module.firewall.private_ip_address
  subnet_ids                  = [module.spoke_network.aks_subnet_id, module.spoke_network.app_subnet_id]
  tags                        = local.common_tags
}

module "vnet_peering" {
  source = "./modules/vnet-peering"

  hub_to_spoke_name    = "${local.name_prefix}-hub-to-spoke"
  spoke_to_hub_name    = "${local.name_prefix}-spoke-to-hub"
  hub_resource_group   = module.resource_group.name
  spoke_resource_group = module.resource_group.name
  hub_vnet_name        = module.hub_network.name
  spoke_vnet_name      = module.spoke_network.name
  hub_vnet_id          = module.hub_network.id
  spoke_vnet_id        = module.spoke_network.id
}

module "bastion" {
  source = "./modules/bastion"

  name                = "${local.name_prefix}-bas"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  subnet_id           = module.hub_network.azure_bastion_subnet_id
  public_ip_enabled   = var.bastion_public_ip_enabled
  tags                = local.common_tags
}

module "application_gateway" {
  source = "./modules/application-gateway"

  name                 = "${local.name_prefix}-agw"
  location             = module.resource_group.location
  resource_group_name  = module.resource_group.name
  subnet_id            = module.hub_network.application_gateway_subnet_id
  backend_ip_addresses = local.app_gateway_backend_addresses
  backend_fqdns        = var.app_gateway_backend_fqdns
  host_names           = var.app_gateway_host_names
  tags                 = local.common_tags
}

module "key_vault" {
  source = "./modules/key-vault"

  name                           = replace(substr("${var.project_name}-${var.environment}-kv", 0, 24), "-", "")
  location                       = module.resource_group.location
  resource_group_name            = module.resource_group.name
  soft_delete_retention_days     = var.key_vault_soft_delete_retention_days
  private_endpoint_subnet_id     = module.spoke_network.private_endpoint_subnet_id
  private_dns_zone_vnet_id       = module.spoke_network.id
  log_analytics_workspace_id     = module.log_analytics.id
  admin_object_ids               = var.key_vault_admin_object_ids
  secrets_user_object_ids        = var.key_vault_secrets_user_object_ids
  assign_current_principal_admin = var.key_vault_assign_current_principal_admin
  tags                           = local.common_tags
}

module "aks" {
  source = "./modules/aks"

  name                       = "${local.name_prefix}-aks"
  location                   = module.resource_group.location
  resource_group_name        = module.resource_group.name
  dns_prefix                 = replace(local.name_prefix, "_", "-")
  kubernetes_version         = var.aks_kubernetes_version
  node_count                 = var.aks_node_count
  vm_size                    = var.aks_vm_size
  availability_zones         = var.aks_availability_zones
  subnet_id                  = module.spoke_network.aks_subnet_id
  service_cidr               = var.aks_service_cidr
  dns_service_ip             = var.aks_dns_service_ip
  admin_group_object_ids     = var.aks_admin_group_object_ids
  log_analytics_workspace_id = module.log_analytics.id
  tags                       = local.common_tags

  depends_on = [
    module.route_table,
    module.vnet_peering
  ]
}

resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = module.spoke_network.id
  role_definition_name = "Network Contributor"
  principal_id         = module.aks.principal_id
}

resource "azurerm_role_assignment" "aks_subnet_network_contributor" {
  scope                = module.spoke_network.aks_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = module.aks.principal_id
}

module "security" {
  source = "./modules/security"

  environment                 = var.environment
  resource_group_id           = module.resource_group.id
  log_analytics_workspace_id  = module.log_analytics.id
  key_vault_id                = module.key_vault.id
  aks_cluster_id              = module.aks.id
  policy_assignment_enabled   = false
  defender_assignment_enabled = false
  tags                        = local.common_tags
}
