#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

TERRAFORM_BIN="$(resolve_terraform)"
ENVIRONMENT="${1:-dev}"
PLAN_FILE=".terraform/${ENVIRONMENT}.tfplan"

case "${ENVIRONMENT}" in
  dev | qa | prod) ;;
  *)
    echo "Usage: $0 [dev|qa|prod]" >&2
    exit 1
    ;;
esac

if [[ ! -f "${PLAN_FILE}" ]]; then
  echo "Plan file ${PLAN_FILE} not found. Run scripts/plan.sh ${ENVIRONMENT} first." >&2
  exit 1
fi

"${TERRAFORM_BIN}" apply "${PLAN_FILE}"
