#!/usr/bin/env bash
set -euo pipefail

if ! command -v tflint >/dev/null 2>&1; then
  echo "tflint is not installed; skipping optional lint."
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TFLINT_CONFIG="${SCRIPT_DIR}/../.tflint.hcl"

tflint --init --config "${TFLINT_CONFIG}"
tflint --recursive --config "${TFLINT_CONFIG}"
