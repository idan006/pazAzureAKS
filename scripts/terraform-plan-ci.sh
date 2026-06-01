#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

ENVIRONMENT="${1:?Usage: $0 <dev|qa|prod>}"

case "${ENVIRONMENT}" in
  dev | qa | prod) ;;
  *)
    echo "Usage: $0 <dev|qa|prod>" >&2
    exit 1
    ;;
esac

TERRAFORM_BIN="$(resolve_terraform)"
PLAN_DIR="artifacts/plans/${ENVIRONMENT}"
PLAN_FILE="${PLAN_DIR}/tfplan.bin"

mkdir -p "${PLAN_DIR}"

"${TERRAFORM_BIN}" init -reconfigure -input=false -backend-config="backend/${ENVIRONMENT}.backend.hcl"
"${TERRAFORM_BIN}" plan -input=false -no-color -var-file="envs/${ENVIRONMENT}.tfvars" -out="${PLAN_FILE}"
"${TERRAFORM_BIN}" show -no-color "${PLAN_FILE}" >"${PLAN_DIR}/tfplan.txt"
"${TERRAFORM_BIN}" show -json "${PLAN_FILE}" >"${PLAN_DIR}/tfplan.json"

echo "Terraform plan saved to ${PLAN_FILE}"
