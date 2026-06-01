#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

TERRAFORM_BIN="$(resolve_terraform)"
"${TERRAFORM_BIN}" init -reconfigure -backend-config=backend/prod.backend.hcl
