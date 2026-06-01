resource "azurerm_kubernetes_cluster" "this" {
  name                              = var.name
  location                          = var.location
  resource_group_name               = var.resource_group_name
  dns_prefix                        = var.dns_prefix
  kubernetes_version                = var.kubernetes_version
  private_cluster_enabled           = true
  private_dns_zone_id               = "System"
  role_based_access_control_enabled = true
  azure_policy_enabled              = var.azure_policy_enabled
  oidc_issuer_enabled               = var.oidc_issuer_enabled
  workload_identity_enabled         = var.workload_identity_enabled
  local_account_disabled            = var.local_account_disabled
  sku_tier                          = var.sku_tier
  tags                              = var.tags

  default_node_pool {
    name                   = "system"
    vm_size                = var.vm_size
    node_count             = var.node_count
    vnet_subnet_id         = var.subnet_id
    zones                  = var.availability_zones
    max_pods               = var.max_pods
    os_disk_size_gb        = var.os_disk_size_gb
    node_public_ip_enabled = false
    type                   = "VirtualMachineScaleSets"

    upgrade_settings {
      max_surge = "10%"
    }
  }

  dynamic "azure_active_directory_role_based_access_control" {
    for_each = length(var.admin_group_object_ids) > 0 ? [1] : []

    content {
      azure_rbac_enabled     = true
      admin_group_object_ids = var.admin_group_object_ids
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    outbound_type     = "userDefinedRouting"
    load_balancer_sku = "standard"
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }
}
