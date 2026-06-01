#!/usr/bin/env bash
set -euo pipefail

if ! command -v tflint >/dev/null 2>&1; then
  echo "tflint is not installed; skipping optional lint."
  exit 0
fi

tflint --init
tflint --recursive
