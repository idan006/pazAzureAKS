#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib-test.sh"

required_modules=(
  "resource-group"
  "log-analytics"
  "hub-network"
  "spoke-network"
  "vnet-peering"
  "firewall"
  "bastion"
  "application-gateway"
  "route-table"
  "aks"
  "key-vault"
  "security"
)

for module in "${required_modules[@]}"; do
  module_dir="modules/${module}"
  require_dir "${module_dir}"
  require_file "${module_dir}/main.tf"
  require_file "${module_dir}/variables.tf"
  require_file "${module_dir}/outputs.tf"
  require_pattern "${module_dir}/variables.tf" '^variable "[^"]+"' "${module} exposes at least one input variable"
  require_pattern "${module_dir}/outputs.tf" '^output "[^"]+"' "${module} exposes at least one output"
done

for module_dir in modules/*; do
  [[ -d "${module_dir}" ]] || continue

  for contract_file in main.tf variables.tf outputs.tf; do
    require_file "${module_dir}/${contract_file}"
  done
done

finish_tests
