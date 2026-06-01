#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib-test.sh"

require_pattern "modules/aks/main.tf" "private_cluster_enabled[[:space:]]*=[[:space:]]*true" "AKS private API is enabled"
require_pattern "modules/aks/main.tf" "node_public_ip_enabled[[:space:]]*=[[:space:]]*false" "AKS nodes do not receive public IPs"
require_pattern "modules/aks/main.tf" "network_plugin[[:space:]]*=[[:space:]]*\"azure\"" "AKS uses Azure CNI"
require_pattern "modules/aks/main.tf" "network_policy[[:space:]]*=[[:space:]]*\"azure\"" "AKS uses Azure Network Policy"
require_pattern "modules/aks/main.tf" "outbound_type[[:space:]]*=[[:space:]]*\"userDefinedRouting\"" "AKS egress uses UDR"
require_pattern "modules/aks/main.tf" "workload_identity_enabled[[:space:]]*=[[:space:]]*var\\.workload_identity_enabled" "AKS workload identity is wired"
require_pattern "modules/aks/main.tf" "oms_agent" "AKS sends logs to Log Analytics"

require_pattern "modules/spoke-network/main.tf" "DenyInternetInbound" "Spoke NSGs deny inbound internet traffic"
require_pattern "modules/route-table/main.tf" "0\\.0\\.0\\.0/0" "Route table defines a default route"
require_pattern "modules/route-table/main.tf" "VirtualAppliance" "Route table forwards traffic to a virtual appliance"
require_pattern "main.tf" "firewall_private_ip_address[[:space:]]*=[[:space:]]*module\\.firewall\\.private_ip_address" "UDR next hop uses Azure Firewall private IP"

require_pattern "modules/application-gateway/main.tf" "azurerm_public_ip" "Application Gateway owns the public entry point"
require_pattern "modules/application-gateway/main.tf" "WAF_v2" "Application Gateway uses WAF v2"
require_pattern "modules/application-gateway/main.tf" "azurerm_web_application_firewall_policy" "Application Gateway uses a dedicated WAF policy"
require_pattern "modules/application-gateway/main.tf" "mode[[:space:]]*=[[:space:]]*var\\.waf_mode" "WAF mode is configurable"

require_pattern "variables.tf" "firewall_public_ip_enabled.*" "Firewall public IP is controlled by an explicit variable"
require_pattern "variables.tf" "default[[:space:]]*=[[:space:]]*false" "Optional public IP controls default to false"
require_pattern "main.tf" "public_ip_enabled[[:space:]]*=[[:space:]]*var\\.firewall_public_ip_enabled" "Firewall public IP is not hard-coded on"
require_pattern "main.tf" "public_ip_enabled[[:space:]]*=[[:space:]]*var\\.bastion_public_ip_enabled" "Bastion public IP is not hard-coded on"

require_pattern "modules/key-vault/main.tf" "public_network_access_enabled[[:space:]]*=[[:space:]]*false" "Key Vault public network access is disabled"
require_pattern "modules/key-vault/main.tf" "purge_protection_enabled[[:space:]]*=[[:space:]]*true" "Key Vault purge protection is enabled"
require_pattern "modules/key-vault/main.tf" "default_action[[:space:]]*=[[:space:]]*\"Deny\"" "Key Vault network ACL defaults to deny"
require_pattern "modules/key-vault/main.tf" "azurerm_private_endpoint" "Key Vault uses a private endpoint"
require_pattern "modules/key-vault/main.tf" "privatelink\\.vaultcore\\.azure\\.net" "Key Vault private DNS zone is configured"
require_pattern "modules/key-vault/main.tf" "azurerm_monitor_diagnostic_setting" "Key Vault diagnostics are sent to Log Analytics"
require_pattern "modules/key-vault/main.tf" "Key Vault Administrator" "Key Vault admin RBAC is explicit"
require_pattern "modules/key-vault/main.tf" "Key Vault Secrets User" "Key Vault secret consumer RBAC is explicit"

require_absent_pattern "modules/aks/main.tf" "azurerm_public_ip" "AKS module does not create public IP resources"
require_absent_pattern "modules/spoke-network/main.tf" "azurerm_public_ip" "Spoke network module does not create public IP resources"

finish_tests
