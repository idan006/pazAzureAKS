# Secret Management Runbook

This project uses Azure Key Vault for production-grade secret management.
Secrets should not be stored in Terraform variables, GitHub repository files, or
Kubernetes manifests.

## Design

Key Vault is deployed with:

- RBAC authorization enabled
- Public network access disabled
- Soft delete enabled
- Purge protection enabled
- Network ACL default action set to deny
- Private endpoint in the spoke private endpoint subnet
- Private DNS zone `privatelink.vaultcore.azure.net`
- Private DNS link to the spoke VNet
- Audit diagnostics sent to Log Analytics

## Access Model

Configure long-lived access through Entra ID groups or managed identities:

```hcl
key_vault_admin_object_ids        = ["<entra-admin-group-object-id>"]
key_vault_secrets_user_object_ids = ["<entra-runtime-identity-object-id>"]
```

The Terraform deployer can be granted `Key Vault Administrator` during
bootstrap:

```hcl
key_vault_assign_current_principal_admin = true
```

After durable admin groups are configured, set it to false:

```hcl
key_vault_assign_current_principal_admin = false
```

Use least privilege:

| Role | Intended use |
| --- | --- |
| `Key Vault Administrator` | break-glass and platform admins |
| `Key Vault Secrets User` | workloads or operators that only read secret values |

## Add Or Update A Secret

Run secret commands from a network path that can reach the Key Vault private
endpoint, or from an approved management path.

```bash
az keyvault secret set \
  --vault-name azurehubspokeaksdev \
  --name example-secret \
  --value "<secret-value>"
```

Read a secret:

```bash
az keyvault secret show \
  --vault-name azurehubspokeaksdev \
  --name example-secret \
  --query value \
  --output tsv
```

Do not place secret values in shell history on shared machines. Prefer secure
operator workflows or CI/CD secret injection when available.

## Kubernetes Workload Integration

Preferred production integration:

1. Enable AKS workload identity for the service account.
2. Grant the workload identity `Key Vault Secrets User`.
3. Use the Secrets Store CSI Driver or an application-native Key Vault client.
4. Avoid committing Kubernetes `Secret` manifests with real values.

This repo currently provides the platform-side Key Vault and AKS workload
identity foundation. Add workload-specific bindings when a real application is
introduced.

## GitHub Actions Secrets

GitHub Actions should use OIDC for Azure login:

```text
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
```

Do not store Azure client secrets when OIDC federation is available.

Environment-specific app secrets should be stored in Key Vault or GitHub
Environments, depending on whether they are runtime secrets or CI/CD-only
values.

## Rotation

Recommended rotation pattern:

1. Create a new secret version in Key Vault.
2. Roll the workload so it reloads the value.
3. Validate application health.
4. Disable or expire old versions after the rollback window.

List versions:

```bash
az keyvault secret list-versions \
  --vault-name azurehubspokeaksdev \
  --name example-secret \
  --output table
```

Disable a version only after confirming it is no longer used:

```bash
az keyvault secret set-attributes \
  --vault-name azurehubspokeaksdev \
  --name example-secret \
  --version "<version>" \
  --enabled false
```

## Auditing

Key Vault diagnostics are sent to Log Analytics. Use Azure Monitor or Log
Analytics queries to review secret access patterns.

Example categories to monitor:

- secret reads
- denied operations
- admin role changes
- purge or delete attempts

## Guardrails

- Never commit real secret values.
- Never place storage account keys, SAS tokens, client secrets, private keys, or
  passwords in tfvars.
- Prefer managed identity, workload identity, and OIDC.
- Keep break-glass access in Entra ID groups, not individual user assignments.
- Run `bash tests/no-secrets.sh` before committing.
