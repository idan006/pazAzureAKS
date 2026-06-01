#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:?Usage: $0 <dev|qa|prod>}"

case "${ENVIRONMENT}" in
  dev | qa | prod) ;;
  *)
    echo "Usage: $0 <dev|qa|prod>" >&2
    exit 1
    ;;
esac

BACKEND_FILE="backend/${ENVIRONMENT}.backend.hcl"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
LOCAL_DIR="${LOCAL_DIR:-artifacts/state-backups/${ENVIRONMENT}}"

backend_value() {
  local key="$1"
  awk -v key="${key}" '$1 == key { gsub(/"/, "", $3); print $3; exit }' "${BACKEND_FILE}"
}

RESOURCE_GROUP_NAME="$(backend_value resource_group_name)"
STORAGE_ACCOUNT_NAME="$(backend_value storage_account_name)"
CONTAINER_NAME="$(backend_value container_name)"
STATE_BLOB_NAME="$(backend_value key)"
BACKUP_BLOB_NAME="${BACKUP_BLOB_NAME:-backups/${ENVIRONMENT}/${TIMESTAMP}.tfstate}"
LOCAL_FILE="${LOCAL_DIR}/${TIMESTAMP}.tfstate"

mkdir -p "${LOCAL_DIR}"

if [[ "$(az storage blob exists --account-name "${STORAGE_ACCOUNT_NAME}" --container-name "${CONTAINER_NAME}" --name "${STATE_BLOB_NAME}" --auth-mode login --query exists -o tsv)" != "true" ]]; then
  echo "State blob not found: ${CONTAINER_NAME}/${STATE_BLOB_NAME}" >&2
  exit 1
fi

az storage blob download \
  --account-name "${STORAGE_ACCOUNT_NAME}" \
  --container-name "${CONTAINER_NAME}" \
  --name "${STATE_BLOB_NAME}" \
  --file "${LOCAL_FILE}" \
  --auth-mode login \
  --only-show-errors \
  --output none

az storage blob upload \
  --account-name "${STORAGE_ACCOUNT_NAME}" \
  --container-name "${CONTAINER_NAME}" \
  --name "${BACKUP_BLOB_NAME}" \
  --file "${LOCAL_FILE}" \
  --auth-mode login \
  --overwrite false \
  --only-show-errors \
  --output none

echo "Terraform state backed up."
echo "Resource group: ${RESOURCE_GROUP_NAME}"
echo "Storage account: ${STORAGE_ACCOUNT_NAME}"
echo "Container: ${CONTAINER_NAME}"
echo "Source blob: ${STATE_BLOB_NAME}"
echo "Backup blob: ${BACKUP_BLOB_NAME}"
echo "Local copy: ${LOCAL_FILE}"
