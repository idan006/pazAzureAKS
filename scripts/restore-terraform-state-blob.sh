#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:?Usage: $0 <dev|qa|prod> <backup-blob-name> --confirm}"
BACKUP_BLOB_NAME="${2:?Usage: $0 <dev|qa|prod> <backup-blob-name> --confirm}"
CONFIRMATION="${3:-}"

case "${ENVIRONMENT}" in
  dev | qa | prod) ;;
  *)
    echo "Usage: $0 <dev|qa|prod> <backup-blob-name> --confirm" >&2
    exit 1
    ;;
esac

if [[ "${CONFIRMATION}" != "--confirm" ]]; then
  echo "Refusing to overwrite Terraform state without --confirm." >&2
  echo "Usage: $0 <dev|qa|prod> <backup-blob-name> --confirm" >&2
  exit 1
fi

BACKEND_FILE="backend/${ENVIRONMENT}.backend.hcl"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
LOCAL_DIR="${LOCAL_DIR:-artifacts/state-restores/${ENVIRONMENT}}"

backend_value() {
  local key="$1"
  awk -v key="${key}" '$1 == key { gsub(/"/, "", $3); print $3; exit }' "${BACKEND_FILE}"
}

RESOURCE_GROUP_NAME="$(backend_value resource_group_name)"
STORAGE_ACCOUNT_NAME="$(backend_value storage_account_name)"
CONTAINER_NAME="$(backend_value container_name)"
STATE_BLOB_NAME="$(backend_value key)"
PRE_RESTORE_BLOB_NAME="backups/${ENVIRONMENT}/pre-restore-${TIMESTAMP}.tfstate"
PRE_RESTORE_FILE="${LOCAL_DIR}/pre-restore-${TIMESTAMP}.tfstate"
RESTORE_FILE="${LOCAL_DIR}/restore-${TIMESTAMP}.tfstate"

mkdir -p "${LOCAL_DIR}"

if [[ "$(az storage blob exists --account-name "${STORAGE_ACCOUNT_NAME}" --container-name "${CONTAINER_NAME}" --name "${BACKUP_BLOB_NAME}" --auth-mode login --query exists -o tsv)" != "true" ]]; then
  echo "Backup blob not found: ${CONTAINER_NAME}/${BACKUP_BLOB_NAME}" >&2
  exit 1
fi

if [[ "$(az storage blob exists --account-name "${STORAGE_ACCOUNT_NAME}" --container-name "${CONTAINER_NAME}" --name "${STATE_BLOB_NAME}" --auth-mode login --query exists -o tsv)" == "true" ]]; then
  az storage blob download \
    --account-name "${STORAGE_ACCOUNT_NAME}" \
    --container-name "${CONTAINER_NAME}" \
    --name "${STATE_BLOB_NAME}" \
    --file "${PRE_RESTORE_FILE}" \
    --auth-mode login \
    --only-show-errors \
    --output none

  az storage blob upload \
    --account-name "${STORAGE_ACCOUNT_NAME}" \
    --container-name "${CONTAINER_NAME}" \
    --name "${PRE_RESTORE_BLOB_NAME}" \
    --file "${PRE_RESTORE_FILE}" \
    --auth-mode login \
    --overwrite false \
    --only-show-errors \
    --output none
fi

az storage blob download \
  --account-name "${STORAGE_ACCOUNT_NAME}" \
  --container-name "${CONTAINER_NAME}" \
  --name "${BACKUP_BLOB_NAME}" \
  --file "${RESTORE_FILE}" \
  --auth-mode login \
  --only-show-errors \
  --output none

az storage blob upload \
  --account-name "${STORAGE_ACCOUNT_NAME}" \
  --container-name "${CONTAINER_NAME}" \
  --name "${STATE_BLOB_NAME}" \
  --file "${RESTORE_FILE}" \
  --auth-mode login \
  --overwrite true \
  --only-show-errors \
  --output none

echo "Terraform state restored."
echo "Resource group: ${RESOURCE_GROUP_NAME}"
echo "Storage account: ${STORAGE_ACCOUNT_NAME}"
echo "Container: ${CONTAINER_NAME}"
echo "Restored blob: ${STATE_BLOB_NAME}"
echo "Source backup blob: ${BACKUP_BLOB_NAME}"
echo "Pre-restore backup blob: ${PRE_RESTORE_BLOB_NAME}"
