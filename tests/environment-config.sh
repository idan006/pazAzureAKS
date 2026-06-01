#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib-test.sh"

declare -A expected_spoke_cidr=(
  [dev]="10.10.0.0/16"
  [qa]="10.20.0.0/16"
  [prod]="10.30.0.0/16"
)

declare -A expected_nginx_ip=(
  [dev]="10.10.1.100"
  [qa]="10.20.1.100"
  [prod]="10.30.1.100"
)

for env in dev qa prod; do
  tfvars="envs/${env}.tfvars"
  backend="backend/${env}.backend.hcl"

  require_file "${tfvars}"
  require_file "${backend}"
  require_pattern "${tfvars}" "^environment[[:space:]]*=[[:space:]]*\"${env}\"" "${env} tfvars declares the matching environment"
  require_pattern "${tfvars}" "${expected_spoke_cidr[${env}]}" "${env} uses expected spoke CIDR ${expected_spoke_cidr[${env}]}"
  require_pattern "${tfvars}" "nginx_ingress_private_ip[[:space:]]*=[[:space:]]*\"${expected_nginx_ip[${env}]}\"" "${env} nginx ingress private IP is pinned"
  require_pattern "${tfvars}" "aks-subnet" "${env} defines aks-subnet"
  require_pattern "${tfvars}" "app-subnet" "${env} defines app-subnet"
  require_pattern "${tfvars}" "private-endpoint-subnet" "${env} defines private-endpoint-subnet"
  require_pattern "${backend}" "key[[:space:]]*=[[:space:]]*\"azure-hub-spoke-aks/${env}\\.tfstate\"" "${env} backend state key is isolated"
  require_pattern "${backend}" "use_azuread_auth[[:space:]]*=[[:space:]]*true" "${env} backend uses Azure AD auth"
done

finish_tests
