# Remote State Backup And Restore Runbook

Terraform remote state is stored in Azure Blob Storage using Azure AD
authentication.

## Backend Layout

Backend configuration files live under `backend/`:

```text
backend/dev.backend.hcl
backend/qa.backend.hcl
backend/prod.backend.hcl
```

Default state blob keys:

```text
azure-hub-spoke-aks/dev.tfstate
azure-hub-spoke-aks/qa.tfstate
azure-hub-spoke-aks/prod.tfstate
```

The bootstrap stack creates:

- Resource group for state
- Storage account
- Blob container
- Storage hardening settings

## Required Access

The operator identity needs data-plane access to the state container. The
recommended role is:

```text
Storage Blob Data Contributor
```

Use Azure AD authentication. Do not use storage account keys or SAS tokens in
repo files.

## Back Up State

Back up an environment state blob:

```bash
bash scripts/backup-terraform-state-blob.sh dev
```

The script:

- Reads the backend settings from `backend/dev.backend.hcl`
- Downloads the live state blob to `artifacts/state-backups/dev/`
- Uploads a timestamped backup blob under `backups/dev/`

Example backup blob:

```text
backups/dev/20260601T120000Z.tfstate
```

List backups:

```bash
az storage blob list \
  --account-name stpaztfstate001 \
  --container-name tfstate \
  --prefix backups/dev/ \
  --auth-mode login \
  --output table
```

## Restore State

Restoring state overwrites the live state blob. Use it only after confirming
the target environment and backup blob.

Restore:

```bash
bash scripts/restore-terraform-state-blob.sh dev backups/dev/20260601T120000Z.tfstate --confirm
```

The restore script:

- Downloads the selected backup blob
- Creates a pre-restore backup of the current live state
- Uploads the selected backup over the live state key

## Post-Restore Validation

After restoring state:

```bash
bash scripts/init-dev.sh
bash scripts/plan.sh dev
```

Review the plan carefully. A large plan may be expected if the restored state is
older than the cloud resources. Do not apply until the drift is understood.

Check that the state blob exists:

```bash
az storage blob exists \
  --account-name stpaztfstate001 \
  --container-name tfstate \
  --name azure-hub-spoke-aks/dev.tfstate \
  --auth-mode login \
  --output json
```

## Recovery Notes

- Keep local backup files under `artifacts/`; they are operational artifacts and
  should not be committed.
- Preserve pre-restore backups until the restored environment is verified.
- Do not manually edit state JSON unless there is no safer recovery path.
- Prefer `terraform import` or provider-supported repair over state editing.
