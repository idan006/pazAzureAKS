#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

TERRAFORM_BIN="$(resolve_terraform)"
TFVARS_FILE="terraform.tfvars"

if [[ ! -f "bootstrap/${TFVARS_FILE}" ]]; then
  echo "Create bootstrap/${TFVARS_FILE} from bootstrap/terraform.tfvars.example and set a globally unique storage_account_name." >&2
  exit 1
fi

"${TERRAFORM_BIN}" -chdir=bootstrap init
"${TERRAFORM_BIN}" -chdir=bootstrap apply -var-file="${TFVARS_FILE}"
