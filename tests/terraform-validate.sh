#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../scripts/lib.sh"

TERRAFORM_BIN="$(resolve_terraform)"
"${TERRAFORM_BIN}" init -backend=false -input=false
"${TERRAFORM_BIN}" validate
