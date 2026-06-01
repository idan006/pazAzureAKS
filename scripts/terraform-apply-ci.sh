#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

ENVIRONMENT="${1:?Usage: $0 <dev|qa|prod> [plan-file]}"
PLAN_FILE="${2:-artifacts/plans/${ENVIRONMENT}/tfplan.bin}"

case "${ENVIRONMENT}" in
  dev | qa | prod) ;;
  *)
    echo "Usage: $0 <dev|qa|prod> [plan-file]" >&2
    exit 1
    ;;
esac

if [[ ! -f "${PLAN_FILE}" ]]; then
  echo "Plan file not found: ${PLAN_FILE}" >&2
  exit 1
fi

TERRAFORM_BIN="$(resolve_terraform)"

"${TERRAFORM_BIN}" init -reconfigure -input=false -backend-config="backend/${ENVIRONMENT}.backend.hcl"
"${TERRAFORM_BIN}" apply -input=false -auto-approve "${PLAN_FILE}"
"${TERRAFORM_BIN}" output -json >"artifacts/plans/${ENVIRONMENT}/outputs.json"
