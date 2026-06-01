#!/usr/bin/env bash
set -euo pipefail

PLAN_JSON="${1:?Usage: $0 <terraform-plan.json>}"
REQUIRE_POLICY_TOOL="${REQUIRE_POLICY_TOOL:-false}"
RUN_CONTAINER_SCANS="${RUN_CONTAINER_SCANS:-false}"
CONFTEST_IMAGE="${CONFTEST_IMAGE:-openpolicyagent/conftest:v0.56.0}"

if [[ ! -f "${PLAN_JSON}" ]]; then
  echo "Terraform plan JSON not found: ${PLAN_JSON}" >&2
  exit 1
fi

if command -v conftest >/dev/null 2>&1; then
  conftest test --policy policies/conftest "${PLAN_JSON}"
elif [[ "${RUN_CONTAINER_SCANS}" == "true" ]] && command -v docker >/dev/null 2>&1; then
  docker run --rm -v "${PWD}:/workspace" -w /workspace "${CONFTEST_IMAGE}" test --policy policies/conftest "${PLAN_JSON}"
elif [[ "${REQUIRE_POLICY_TOOL}" == "true" ]]; then
  echo "conftest is required but not installed and container fallback is unavailable." >&2
  exit 127
else
  echo "SKIP: conftest is not installed; policy-as-code checks skipped."
fi
