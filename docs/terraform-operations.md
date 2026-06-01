# Terraform Operations Runbook

This runbook covers day-to-day infrastructure operations for the Azure
Hub-Spoke AKS platform.

## Ownership Boundary

Terraform owns Azure infrastructure:

- Resource group
- Hub and spoke VNets
- Subnets, NSGs, route tables, and peering
- Application Gateway WAF
- Azure Firewall
- Azure Bastion
- AKS
- Log Analytics
- Key Vault, private endpoint, Private DNS, diagnostics, and RBAC assignments
- Terraform remote state bootstrap resources

Helm owns Kubernetes application releases. Do not use Terraform for app
deployment objects such as the `hello-world` deployment, service, or ingress.

## Environment Files

Each environment has one tfvars file and one backend config:

| Environment | tfvars | Backend |
| --- | --- | --- |
| dev | `envs/dev.tfvars` | `backend/dev.backend.hcl` |
| qa | `envs/qa.tfvars` | `backend/qa.backend.hcl` |
| prod | `envs/prod.tfvars` | `backend/prod.backend.hcl` |

Each environment uses a separate state key:

```text
azure-hub-spoke-aks/dev.tfstate
azure-hub-spoke-aks/qa.tfstate
azure-hub-spoke-aks/prod.tfstate
```

## Standard Workflow

Initialize the backend before planning or applying:

```bash
bash scripts/init-dev.sh
```

Plan:

```bash
bash scripts/plan.sh dev
```

Apply:

```bash
bash scripts/apply.sh dev
```

Repeat with `qa` or `prod` when promoting changes.

## Local Validation Before Apply

Run all local checks:

```bash
bash scripts/validate-all.sh
```

Useful targeted checks:

```bash
bash tests/terraform-fmt.sh
bash tests/terraform-validate.sh
bash tests/security-architecture.sh
bash tests/environment-config.sh
bash tests/no-secrets.sh
```

If Terraform is installed outside `PATH`, set:

```bash
export TERRAFORM_BIN="/mnt/c/Terraform/terraform.exe"
```

## Plan Review Checklist

Before applying a plan, confirm:

- The selected backend matches the target environment.
- The selected tfvars file matches the target environment.
- There are no unexpected resource replacements.
- Public IP changes are expected.
- AKS node pool changes are expected.
- Key Vault RBAC or network changes are expected.
- Route table and firewall changes preserve private AKS egress.
- Application Gateway backend still points to the intended nginx ingress IP.

For production, always review the saved CI plan artifact before approval.

## Apply Safety

Use the wrapper scripts so the correct backend and tfvars are selected:

```bash
bash scripts/apply.sh prod
```

Avoid raw `terraform apply` unless the backend is already initialized and you
are certain which environment state is active.

Avoid `terraform apply -target` for routine work. Targeting is acceptable only
for recovery or narrow operational repair, and should be followed by a normal
plan to understand remaining drift.

## Drift Detection

Run a plan without applying:

```bash
bash scripts/init-dev.sh
bash scripts/plan.sh dev
```

Investigate any unexpected changes. Common drift sources:

- Manual portal edits
- Emergency Azure CLI changes
- Provider default changes after an upgrade
- AKS-managed resources in the node resource group
- Temporary troubleshooting changes to Application Gateway backend settings

## State Locking

The Azure Storage backend uses state locking. If a run fails while holding a
lock, wait for the process to exit and retry. Do not force-unlock unless you
have confirmed no Terraform process is still running.

Check local processes:

```bash
ps -ef | rg 'terraform|terraform.exe' || true
```

## Outputs

Common outputs:

```bash
terraform output
terraform output -raw resource_group_name
terraform output -raw aks_cluster_name
terraform output -raw aks_private_fqdn
terraform output -raw application_gateway_public_ip
terraform output -raw firewall_private_ip
terraform output -raw key_vault_uri
```

## Health Verification After Apply

Check Azure resources:

```bash
az aks show \
  --resource-group azure-hub-spoke-aks-dev-rg \
  --name azure-hub-spoke-aks-dev-aks \
  --query '{state:provisioningState,power:powerState.code,version:kubernetesVersion}' \
  --output json

az network application-gateway show \
  --resource-group azure-hub-spoke-aks-dev-rg \
  --name azure-hub-spoke-aks-dev-agw \
  --query '{state:provisioningState,operationalState:operationalState}' \
  --output json

az resource show \
  --resource-group azure-hub-spoke-aks-dev-rg \
  --name azure-hub-spoke-aks-dev-afw \
  --resource-type Microsoft.Network/azureFirewalls \
  --query '{state:properties.provisioningState,privateIp:properties.ipConfigurations[0].properties.privateIPAddress}' \
  --output json
```

Check App Gateway backend health:

```bash
az network application-gateway show-backend-health \
  --resource-group azure-hub-spoke-aks-dev-rg \
  --name azure-hub-spoke-aks-dev-agw \
  --query 'backendAddressPools[].backendHttpSettingsCollection[].servers[].{address:address,health:health,log:healthProbeLog}' \
  --output table
```

Run the interactive network security validation helper:

```bash
python3 scripts/validate-network-controls.py
```

Run all checks non-interactively:

```bash
python3 scripts/validate-network-controls.py --environment dev --all
```

## Cleanup

Destroy only when intentional:

```bash
bash scripts/init-dev.sh
terraform destroy -var-file=envs/dev.tfvars
```

Remote state resources are managed by the bootstrap stack. Destroy bootstrap
resources only after all environment states are backed up and no longer needed.
