#!/usr/bin/env bash
set -euo pipefail

REQUIRE_SECURITY_TOOLS="${REQUIRE_SECURITY_TOOLS:-false}"
RUN_CONTAINER_SCANS="${RUN_CONTAINER_SCANS:-false}"
CHECKOV_IMAGE="${CHECKOV_IMAGE:-bridgecrew/checkov:3.2.471}"
TRIVY_IMAGE="${TRIVY_IMAGE:-aquasec/trivy:0.71.0}"
GITLEAKS_IMAGE="${GITLEAKS_IMAGE:-zricethezav/gitleaks:v8.30.1}"

missing_tool() {
  local name="$1"

  if [[ "${REQUIRE_SECURITY_TOOLS}" == "true" ]]; then
    echo "Required security tool is unavailable: ${name}" >&2
    exit 127
  fi

  echo "SKIP: ${name} is not installed and container fallback is disabled."
}

can_use_docker() {
  [[ "${RUN_CONTAINER_SCANS}" == "true" ]] && command -v docker >/dev/null 2>&1
}

echo "==> Checkov"
if command -v checkov >/dev/null 2>&1; then
  checkov -d . --config-file .checkov.yml
elif can_use_docker; then
  docker run --rm -v "${PWD}:/workspace" -w /workspace "${CHECKOV_IMAGE}" -d /workspace --config-file /workspace/.checkov.yml
else
  missing_tool "checkov"
fi

echo "==> Trivy IaC and secret scan"
if command -v trivy >/dev/null 2>&1; then
  trivy config --config trivy.yaml --exit-code 1 .
elif can_use_docker; then
  docker run --rm -v "${PWD}:/workspace" -w /workspace "${TRIVY_IMAGE}" config --config /workspace/trivy.yaml --exit-code 1 /workspace
else
  missing_tool "trivy"
fi

echo "==> Gitleaks"
if command -v gitleaks >/dev/null 2>&1; then
  gitleaks detect --source . --config .gitleaks.toml --redact --verbose
elif can_use_docker; then
  docker run --rm -v "${PWD}:/workspace" -w /workspace "${GITLEAKS_IMAGE}" detect --source /workspace --config /workspace/.gitleaks.toml --redact --verbose
else
  missing_tool "gitleaks"
fi

echo "Security scan completed."
