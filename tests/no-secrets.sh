#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib-test.sh"

scan_files="$(mktemp)"
trap 'rm -f "${scan_files}"' EXIT

find . \
  -path "./.git" -prune -o \
  -path "./.terraform" -prune -o \
  -path "./tests/no-secrets.sh" -prune -o \
  -type f \
  \( -name "*.tf" -o -name "*.tfvars" -o -name "*.hcl" -o -name "*.yaml" -o -name "*.yml" -o -name "*.sh" -o -name "README.md" \) \
  -print >"${scan_files}"

while IFS= read -r file; do
  require_absent_pattern "${file}" 'AccountKey=|SharedAccessSignature=|client_secret[[:space:]]*=|password[[:space:]]*=|BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY' "no obvious secret material in ${file}"
done <"${scan_files}"

finish_tests
