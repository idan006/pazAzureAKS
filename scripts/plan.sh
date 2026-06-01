#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

TERRAFORM_BIN="$(resolve_terraform)"
ENVIRONMENT="${1:-dev}"

case "${ENVIRONMENT}" in
  dev | qa | prod) ;;
  *)
    echo "Usage: $0 [dev|qa|prod]" >&2
    exit 1
    ;;
esac

"${TERRAFORM_BIN}" init -reconfigure -backend-config="backend/${ENVIRONMENT}.backend.hcl"
"${TERRAFORM_BIN}" fmt -recursive
"${TERRAFORM_BIN}" validate
"${TERRAFORM_BIN}" plan -var-file="envs/${ENVIRONMENT}.tfvars" -out=".terraform/${ENVIRONMENT}.tfplan"
