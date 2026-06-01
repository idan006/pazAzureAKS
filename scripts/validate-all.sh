#!/usr/bin/env bash
set -euo pipefail

tests=(
  "tests/check-files.sh"
  "tests/module-contracts.sh"
  "tests/environment-config.sh"
  "tests/cicd-config.sh"
  "tests/security-architecture.sh"
  "tests/k8s-manifests.sh"
  "tests/no-secrets.sh"
  "tests/terraform-fmt.sh"
  "tests/terraform-validate.sh"
  "tests/tflint.sh"
)

for test_script in "${tests[@]}"; do
  echo "==> ${test_script}"
  bash "${test_script}"
done

if [[ "${SKIP_SECURITY_SCAN:-false}" == "true" ]]; then
  echo "SKIP: scripts/security-scan.sh disabled by SKIP_SECURITY_SCAN."
else
  echo "==> scripts/security-scan.sh"
  bash scripts/security-scan.sh
fi

echo "Validation suite completed."
