# Azure Hub-Spoke AKS Terraform Platform

Production-oriented Terraform project for deploying a private AKS hello-world platform on Azure using a Hub-Spoke network model.

The default design exposes only one public entry point: Azure Application Gateway WAF in the Hub. Spoke VNets and AKS clusters are private and are not directly reachable from the internet.

## What This Project Builds

- Azure Hub VNet with:
  - Application Gateway WAF
  - Azure Firewall
  - Azure Bastion
  - Shared services subnet
- One private Spoke VNet per deployed environment:
  - `dev`: `10.10.0.0/16`
  - `qa`: `10.20.0.0/16`
  - `prod`: `10.30.0.0/16`
- Private AKS cluster in the spoke
- Azure CNI and Azure Network Policy
- User Defined Routing from AKS/app subnets through Azure Firewall
- NSGs that deny inbound internet traffic to spoke subnets
- Log Analytics integration for AKS
- Key Vault placeholder with private-first settings
- Azure Policy, Defender for Cloud, and workload identity placeholders
- Production Key Vault secret management with RBAC, private endpoint, Private DNS, and diagnostics
- nginx ingress controller inside AKS using an internal Azure Load Balancer
- `nginx:stable` hello-world workload exposed through nginx ingress
- CI/CD workflows for validation, Terraform plan, gated apply, and app deployment

## Architecture

```text
Internet
   |
   v
Application Gateway WAF public IP
   |
   v
Hub VNet
   |-- Azure Firewall
   |-- Azure Bastion
   |-- Shared Services
   |
   +-- VNet Peering
        |
        v
Spoke VNet
   |-- Private AKS subnet
   |     |-- nginx ingress controller
   |     `-- hello-world pods
   |-- App subnet
   `-- Private endpoint subnet
```

Traffic flow:

1. Internet clients connect to Application Gateway WAF.
2. Application Gateway forwards traffic to the private nginx ingress LoadBalancer IP.
3. nginx ingress routes `/` to the hello-world ClusterIP service.
4. The service sends traffic to two `nginx:stable` pods.
5. AKS/app subnet egress follows UDR default routes through Azure Firewall.

Default nginx ingress private IPs:

| Environment | Private IP |
| --- | --- |
| dev | `10.10.1.100` |
| qa | `10.20.1.100` |
| prod | `10.30.1.100` |

## Architecture Explanation

This platform uses a hub-spoke network pattern to keep compute private while
still exposing the application through one controlled public entry point.

The Hub VNet contains shared ingress and security services:

- Application Gateway WAF is the only public application ingress.
- Azure Firewall is the controlled egress next hop for AKS and app subnets.
- Azure Bastion is available for private administrative access patterns.
- Shared services can be added without placing them in workload subnets.

The Spoke VNet contains the workload:

- AKS is deployed as a private cluster.
- AKS nodes do not receive public IPs.
- nginx ingress is exposed with an internal Azure Load Balancer only.
- The hello-world app is exposed to the cluster through a ClusterIP service and
  to the platform through nginx ingress.
- Private endpoints, such as Key Vault, live in a dedicated private endpoint
  subnet.

Connectivity between Hub and Spoke is provided by VNet peering. Application
Gateway forwards traffic from the public listener to the private nginx ingress
IP. Spoke subnet egress follows the User Defined Route to Azure Firewall. There
are no public Kubernetes load balancers, node public IPs, VPN gateways,
ExpressRoute circuits, or NAT gateways in the default design.

Application ownership is split deliberately:

- Terraform owns Azure infrastructure.
- The upstream nginx ingress Helm chart owns the ingress controller.
- The local `charts/hello-world` Helm chart owns the application release.

See `docs/diagram-architecture.md` for Mermaid architecture diagrams and a
visual explanation of the platform.

## Repository Layout

```text
.
|-- .github/
|   |-- workflows/
|   |   |-- validate.yml
|   |   |-- terraform-plan.yml
|   |   |-- terraform-apply.yml
|   |   `-- aks-app-deploy.yml
|   |-- CODEOWNERS
|   `-- dependabot.yml
|-- backend/                  # azurerm backend configs per environment
|-- bootstrap/                # remote state bootstrap stack
|-- charts/
|   `-- hello-world/          # Helm chart for the app release
|-- docs/
|   |-- app-deployment.md     # Helm app deployment and rollback runbook
|   |-- ci-cd.md              # CI/CD setup and promotion details
|   |-- cost-estimation.md    # Monthly Azure run-rate estimate
|   |-- diagram-architecture.md # Mermaid architecture diagrams
|   |-- remote-state.md       # Terraform state backup and restore runbook
|   |-- scaling-strategy.md   # Workload and platform scaling guidance
|   |-- security-considerations.md # Workload protection notes
|   |-- secret-management.md  # Key Vault and secret handling runbook
|   `-- terraform-operations.md # Terraform operations and drift runbook
|-- envs/                     # dev, qa, prod tfvars
|-- k8s/
|   |-- hello-world/          # reference manifests for the app
|   `-- nginx-ingress/        # internal ingress install script
|-- modules/                  # Terraform modules
|-- policies/conftest/        # OPA policy-as-code checks
|-- scripts/                  # local and CI helper scripts
|-- tests/                    # static, Terraform, Kubernetes, and CI/CD checks
|-- .checkov.yml
|-- .gitleaks.toml
|-- .tflint.hcl
|-- trivy.yaml
|-- versions.tf
|-- providers.tf
|-- main.tf
|-- variables.tf
`-- outputs.tf
```

## How To Use

Use this order for a normal rollout:

1. Install prerequisites.
2. Authenticate to Azure.
3. Bootstrap remote Terraform state.
4. Review and edit environment tfvars.
5. Run local validation.
6. Deploy infrastructure with Terraform.
7. Connect from a private network path to AKS.
8. Install nginx ingress and deploy hello-world.
9. Validate the public Application Gateway endpoint.
10. Enable GitHub CI/CD for ongoing changes.

## How To Enroll

Use this checklist when onboarding a new operator, subscription, or environment
to this project.

1. Enroll the Azure subscription:
   - Confirm the target subscription ID.
   - Confirm the subscription has quota for Application Gateway WAF_v2, Azure
     Firewall, Bastion, AKS nodes, public IPs, Log Analytics, and Key Vault.
   - Register the required Azure providers listed below.

2. Enroll the operator identity:
   - Grant permission to create and manage the platform resources.
   - Grant `Storage Blob Data Contributor` on the Terraform state storage
     account after bootstrap.
   - Add durable platform admin groups to `key_vault_admin_object_ids`.
   - Add runtime secret readers to `key_vault_secrets_user_object_ids`.

3. Enroll local tooling:
   - Install Azure CLI, Terraform, Bash, kubectl, Helm, and Python 3.
   - Authenticate with `az login`.
   - Set `ARM_SUBSCRIPTION_ID`.
   - Set `TERRAFORM_BIN` if Terraform is not on `PATH`.

4. Enroll remote state:
   - Create or update `bootstrap/terraform.tfvars`.
   - Run `bash scripts/bootstrap-state.sh`.
   - Confirm `backend/dev.backend.hcl`, `backend/qa.backend.hcl`, and
     `backend/prod.backend.hcl` point to the correct storage account.

5. Enroll environments:
   - Review `envs/dev.tfvars`, `envs/qa.tfvars`, and `envs/prod.tfvars`.
   - Confirm address spaces do not overlap existing networks.
   - Confirm nginx ingress private IPs are inside the AKS subnet.
   - Confirm tags, node sizes, and admin group object IDs are correct.

6. Enroll CI/CD:
   - Create GitHub Environments named `dev`, `qa`, and `prod`.
   - Configure Azure OIDC federation for GitHub Actions.
   - Add `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and
     `AZURE_SUBSCRIPTION_ID`.
   - Configure a private self-hosted runner with labels `self-hosted`,
     `linux`, and `aks-private` for app deployment.

7. Enroll workstation validation:
   - Add the Application Gateway public IP to a local hosts entry when using a
     friendly local name, for example:

```text
135.237.38.92 hello-world.local # paz-hello-world
```

## Deployment Stages

The project is deployed in clear stages so infrastructure, networking, security,
and application release management stay separated.

| Stage | Owner | Commands | Result |
| --- | --- | --- | --- |
| 1. Bootstrap state | Terraform bootstrap | `bash scripts/bootstrap-state.sh` | Azure Storage backend exists |
| 2. Validate locally | Tests/scripts | `bash scripts/validate-all.sh` | Static checks pass before cloud changes |
| 3. Plan infrastructure | Terraform | `bash scripts/plan.sh dev` | Reviewed Terraform plan |
| 4. Apply infrastructure | Terraform | `bash scripts/apply.sh dev` | Hub, spoke, AKS, security, and stateful Azure resources exist |
| 5. Install ingress | Helm upstream chart | `bash scripts/install-nginx-ingress.sh dev` | Internal nginx ingress LoadBalancer exists |
| 6. Deploy app | Local Helm chart | `bash scripts/deploy-hello-world.sh dev` | `hello-world` Helm release is deployed |
| 7. Validate app | curl/Azure/Kubernetes | `bash scripts/validate-webapp.sh http://hello-world.local/` | HTTP 200 through Application Gateway |
| 8. Validate controls | Python/Azure CLI | `python3 scripts/validate-network-controls.py --environment dev --all` | Network exposure controls pass |
| 9. Promote | GitHub Actions/manual gates | Run the same flow for `qa`, then `prod` | Controlled environment promotion |

Deployment ownership summary:

- `bootstrap/` is used only for Terraform remote state resources.
- Root Terraform deploys Azure platform infrastructure.
- `scripts/install-nginx-ingress.sh` deploys nginx ingress.
- `scripts/deploy-hello-world.sh` deploys the app Helm release.
- `scripts/validate-network-controls.py` validates the three key network
  controls: no direct internet to compute, only Application Gateway ingress, and
  hub-spoke connectivity through VNet peering.

## Prerequisites

Required locally:

- Azure CLI
- Terraform `>= 1.6.0`
- Bash
- kubectl
- Helm
- Python 3 with PyYAML for Kubernetes manifest validation

Recommended locally:

- TFLint
- Checkov
- Trivy
- Gitleaks
- Conftest
- Docker Desktop for containerized scan fallback
- Infracost CLI if you want local cost estimates

Required workstation/network access:

- Internet access to Azure Resource Manager, Azure CLI endpoints, Terraform
  provider downloads, and Helm chart repositories.
- Private network access to the AKS API when running kubectl or Helm directly.
  Use a VM in the Hub/Spoke VNet, VPN, ExpressRoute, or a private self-hosted
  runner.
- Ability to resolve the private AKS API FQDN from the private network path.
- Optional hosts entry for `hello-world.local` when validating from a
  workstation through Application Gateway.

Required Azure permissions:

- Permission to create resource groups, VNets, route tables, NSGs, public IPs, Application Gateway, Firewall, Bastion, AKS, Log Analytics, and Key Vault
- Permission to register required providers
- Permission to create and manage the remote state storage account
- Permission to assign RBAC roles for AKS networking and Key Vault access

Required GitHub configuration for CI/CD:

- GitHub Environments: `dev`, `qa`, and `prod`
- GitHub OIDC federation to Azure
- Repository or organization secrets:
  - `AZURE_CLIENT_ID`
  - `AZURE_TENANT_ID`
  - `AZURE_SUBSCRIPTION_ID`
  - `INFRACOST_API_KEY` when cost estimates are required
- A private self-hosted runner for app deployment with labels:
  - `self-hosted`
  - `linux`
  - `aks-private`

## Azure Login And Provider Registration

```bash
az login
az account set --subscription "<subscription-id>"
export ARM_SUBSCRIPTION_ID="<subscription-id>"
```

Register providers:

```bash
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.Authorization
az provider register --namespace Microsoft.Security
```

## Remote State Bootstrap

Create remote state before deploying environments.

```bash
cp bootstrap/terraform.tfvars.example bootstrap/terraform.tfvars
```

Edit `bootstrap/terraform.tfvars`:

```hcl
location             = "eastus"
resource_group_name  = "rg-tfstate-azure-hub-spoke-aks"
storage_account_name = "youruniquetfstate001"
container_name       = "tfstate"
```

Bootstrap state:

```bash
bash scripts/bootstrap-state.sh
```

Update these files with the same storage account name if you changed it:

```text
backend/dev.backend.hcl
backend/qa.backend.hcl
backend/prod.backend.hcl
```

Each environment uses a separate state key:

```text
azure-hub-spoke-aks/dev.tfstate
azure-hub-spoke-aks/qa.tfstate
azure-hub-spoke-aks/prod.tfstate
```

## Configure Environments

Review and edit:

```text
envs/dev.tfvars
envs/qa.tfvars
envs/prod.tfvars
```

Important values:

- `location`
- `hub_address_space`
- `spoke_address_space`
- `spoke_subnets`
- `nginx_ingress_private_ip`
- `aks_node_count`
- `aks_vm_size`
- `tags`
- `aks_admin_group_object_ids`

Do not commit real secrets into tfvars. Use Azure managed identity, workload identity, GitHub OIDC, and Key Vault-backed runtime integrations.

Key Vault is deployed with:

- RBAC authorization, purge protection, soft delete, and public network access disabled
- A private endpoint in the spoke private endpoint subnet
- `privatelink.vaultcore.azure.net` Private DNS linked to the spoke VNet
- audit diagnostics sent to Log Analytics
- explicit admin and secret-consumer role assignment inputs

Configure secret access with:

```hcl
key_vault_admin_object_ids        = ["<entra-object-id>"]
key_vault_secrets_user_object_ids = ["<entra-object-id>"]
```

The current Terraform deployer is assigned `Key Vault Administrator` by default for bootstrap operations. Set `key_vault_assign_current_principal_admin = false` after you have durable break-glass/admin groups configured.

## Local Validation

Run the full local validation suite:

```bash
bash scripts/validate-all.sh
```

This runs:

- File presence checks
- Module contract checks
- Environment/backend consistency checks
- CI/CD workflow/config checks
- Security architecture checks
- Kubernetes manifest checks
- Basic secret scanning
- `terraform fmt -check`
- `terraform validate`
- Optional TFLint
- Optional Checkov, Trivy, and Gitleaks when installed

You can also run individual tests:

```bash
bash tests/check-files.sh
bash tests/module-contracts.sh
bash tests/environment-config.sh
bash tests/cicd-config.sh
bash tests/security-architecture.sh
bash tests/k8s-manifests.sh
bash tests/no-secrets.sh
bash tests/terraform-fmt.sh
bash tests/terraform-validate.sh
bash tests/tflint.sh
```

## Deploy Infrastructure

Start with `dev`.

```bash
bash scripts/init-dev.sh
bash scripts/plan.sh dev
bash scripts/apply.sh dev
```

Deploy `qa`:

```bash
bash scripts/init-qa.sh
bash scripts/plan.sh qa
bash scripts/apply.sh qa
```

Deploy `prod`:

```bash
bash scripts/init-prod.sh
bash scripts/plan.sh prod
bash scripts/apply.sh prod
```

## Remote State Backup And Restore

Terraform state is stored in Azure Blob Storage using the environment backend files under `backend/`.

Back up an environment state blob:

```bash
bash scripts/backup-terraform-state-blob.sh dev
```

This downloads a local copy under `artifacts/state-backups/` and uploads a timestamped blob under `backups/<environment>/` in the same `tfstate` container.

Restore a state blob from a backup:

```bash
bash scripts/restore-terraform-state-blob.sh dev backups/dev/20260531T190000Z.tfstate --confirm
```

Restore creates a pre-restore backup of the current live state blob before overwriting it.

See `docs/remote-state.md` for the full backup, restore, and post-restore
validation runbook.

Useful outputs:

```bash
terraform output
terraform output -raw application_gateway_public_ip
terraform output -raw aks_cluster_name
terraform output -raw aks_private_fqdn
```

See `docs/terraform-operations.md` for the full Terraform operations, plan
review, drift detection, and cleanup runbook.

## Deploy The Hello-World App

AKS is private. Run these commands from a machine that can resolve and reach the private AKS API, such as:

- A VM in the Hub or Spoke network
- A private self-hosted GitHub runner
- A VPN-connected workstation
- An ExpressRoute-connected host

Get AKS credentials:

```bash
az aks get-credentials \
  --resource-group azure-hub-spoke-aks-dev-rg \
  --name azure-hub-spoke-aks-dev-aks \
  --overwrite-existing
```

Install or upgrade nginx ingress:

```bash
bash scripts/install-nginx-ingress.sh dev
```

Deploy hello-world with Helm:

```bash
bash scripts/deploy-hello-world.sh dev
```

The app chart lives in `charts/hello-world`. Use `values-dev.yaml`, `values-qa.yaml`, and
`values-prod.yaml` for environment-specific release settings. Terraform owns Azure
infrastructure; Helm owns the Kubernetes application release.

See `docs/app-deployment.md` for the full app deployment, rollback, and
troubleshooting runbook.

Useful Helm commands:

```bash
helm status hello-world --namespace default
helm history hello-world --namespace default
helm rollback hello-world <revision> --namespace default --wait --timeout 5m
```

Validate the public endpoint through Application Gateway:

```bash
PUBLIC_IP="$(terraform output -raw application_gateway_public_ip)"
bash scripts/validate-webapp.sh "http://${PUBLIC_IP}/"
```

The validation script expects HTTP 200.

## CI/CD Overview

CI/CD is implemented with GitHub Actions.

| Workflow | Purpose |
| --- | --- |
| `CI - Validate IaC` | Static validation, Terraform checks, Kubernetes checks, TFLint, Checkov, Trivy, Gitleaks, SARIF uploads |
| `Terraform Plan` | Plans dev/qa/prod on PRs, uploads plan artifacts, runs OPA/Conftest, optional Infracost |
| `Terraform Apply` | Manual apply with fresh plan, policy gate, environment approval, serialized per environment |
| `AKS App Deploy` | Manual nginx ingress and hello-world Helm deployment from a private self-hosted runner |

See `docs/ci-cd.md` for the detailed CI/CD process.

See `docs/secret-management.md` for the Key Vault and secret handling runbook.

## GitHub Setup

Create GitHub Environments:

```text
dev
qa
prod
```

Recommended protection:

- `dev`: optional reviewers
- `qa`: required reviewers
- `prod`: required reviewers, restricted branches, optional wait timer

Add repository or organization secrets:

```text
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
INFRACOST_API_KEY
```

`INFRACOST_API_KEY` is optional.

Configure Azure workload identity federation for GitHub Actions. The workflows use OIDC and should not use client secrets.

Replace the placeholder team in `.github/CODEOWNERS`:

```text
* @platform-team
```

Use your real GitHub team or user before enabling branch protection.

## CI/CD Promotion Flow

1. Open a pull request.
2. `CI - Validate IaC` runs local-quality checks and strict security scans.
3. `Terraform Plan` runs for `dev`, `qa`, and `prod` on internal PRs.
4. Review plan summaries and artifacts.
5. Merge to `main`.
6. Manually run `Terraform Apply` for `dev`.
7. Validate the environment.
8. Promote to `qa`.
9. Promote to `prod` after production approval.
10. Run `AKS App Deploy` from the private runner when infrastructure is ready.

## Production-Grade Tooling Included

- Terraform remote state with Azure Storage backend
- Azure OIDC auth for GitHub Actions
- GitHub Environment approval gates
- Workflow concurrency to avoid parallel applies per environment
- CODEOWNERS for ownership enforcement
- Dependabot for GitHub Actions and Terraform dependency updates
- TFLint with AzureRM ruleset config
- Checkov config for Terraform, Kubernetes, and secrets
- Trivy config for IaC and secret scanning
- Gitleaks config for repository secret scanning
- OPA/Conftest policy-as-code for Terraform plan JSON
- Optional Infracost estimate in Terraform plan workflow
- SARIF upload hooks for GitHub code scanning

## Policy-As-Code Rules

OPA policies in `policies/conftest/terraform.rego` deny:

- Public IP resources outside the Application Gateway module
- Public AKS API servers
- AKS node public IPs
- AKS egress that does not use UDR
- Key Vault public network access
- Application Gateway deployments that do not use WAF_v2

Run policy checks against a Terraform plan JSON:

```bash
bash scripts/terraform-plan-ci.sh dev
bash scripts/policy-check.sh artifacts/plans/dev/tfplan.json
```

## Security Model

- Application Gateway WAF is the public ingress point.
- AKS API endpoint is private.
- AKS nodes do not receive public IPs.
- Spoke subnets deny inbound internet traffic through NSGs.
- AKS and app subnets use UDR default routes to Azure Firewall.
- Azure CNI and Azure Network Policy are enabled.
- Log Analytics integration is enabled.
- Key Vault public network access is disabled.
- Key Vault purge protection and soft delete are enabled.
- Workload identity and OIDC issuer support are enabled for AKS.
- Azure Policy and Defender for Cloud placeholders are present for later enforcement.

See `docs/security-considerations.md` for a short explanation of how the
architecture protects this workload.

## Important Azure Firewall And Bastion Note

The project defaults `firewall_public_ip_enabled = false` and `bastion_public_ip_enabled = false` to preserve the one-public-IP architecture.

Azure service SKU and regional support can affect this. If your Azure Firewall deployment requires a public management path or public IP in your target design, add forced-tunneling management support or explicitly set `firewall_public_ip_enabled = true` after accepting that it changes the strict one-public-IP posture.

## Cost Notes

The largest cost drivers are:

- Application Gateway WAF_v2
- Azure Firewall
- Azure Bastion Premium
- AKS node pools
- Log Analytics ingestion and retention

For non-production environments:

- Keep node counts low.
- Destroy idle environments.
- Keep log retention shorter.
- Use Infracost in pull requests before changes are applied.

Production should use appropriate capacity, zone redundancy, backup, monitoring, and retention settings.

See `docs/cost-estimation.md` for the monthly estimate by environment and the
assumptions behind the Azure run-rate.

## Scaling Strategy

Scale in layers: application replicas first, then nginx ingress, AKS nodes,
Application Gateway WAF capacity, and finally shared hub services such as
Firewall and Bastion. Scaling must preserve the private-compute posture: no
public AKS API, no public node IPs, no public Kubernetes LoadBalancer, and
public application traffic only through Application Gateway.

See `docs/scaling-strategy.md` for scaling triggers, commands, and validation
steps.

## Known Limitations

- HTTPS listeners and certificates are not wired into Application Gateway yet.
- DNS records for friendly public hostnames are not included.
- Azure Policy and Defender for Cloud are placeholders, not enforced assignments.
- Application Gateway backend uses the static nginx ingress private IP from tfvars.
- App deployment requires private network access to the AKS API.
- Multi-region failover and blue-green cluster promotion are not included.

## Troubleshooting

Terraform cannot find `terraform` from Bash:

```bash
export TERRAFORM_BIN="/mnt/c/Terraform/terraform.exe"
```

Backend init fails:

- Confirm the storage account name in `backend/*.backend.hcl`.
- Confirm the `tfstate` container exists.
- Confirm your identity has access to the state storage account.

AKS credential command fails:

- Confirm you are on a private network path to the AKS API.
- Confirm private DNS resolution works.
- Confirm the resource group and AKS names match the environment.

Application Gateway returns non-200:

- Confirm nginx ingress is installed.
- Confirm the internal LoadBalancer IP equals `nginx_ingress_private_ip`.
- Confirm the hello-world ingress exists.
- Confirm Application Gateway backend health.

Validate the network security controls with the interactive Python helper:

```bash
python3 scripts/validate-network-controls.py
```

Run all three checks without the menu:

```bash
python3 scripts/validate-network-controls.py --environment dev --all
```

Security scans skip locally:

- Install Checkov, Trivy, Gitleaks, and Conftest.
- Or run with Docker Desktop started and `RUN_CONTAINER_SCANS=true`.

## Production Hardening Checklist

- Add HTTPS listeners, certificates, and HTTP-to-HTTPS redirects.
- Add WAF custom rules and managed rule exclusions based on tested traffic.
- Add private endpoints and private DNS zone links for future PaaS dependencies.
- Replace broad Firewall baseline egress rules with explicit FQDN/application rules.
- Enforce Azure Policy initiatives for AKS baseline, allowed regions, private networking, and required tags.
- Enable Defender for Containers, Key Vault, and Servers.
- Add workload identity bindings for Kubernetes service accounts.
- Add backup and restore procedures for AKS workloads.
- Add cluster upgrade and node image rotation runbooks.
- Add managed Prometheus and Grafana dashboards.
- Add SLOs, alert routing, and incident response runbooks.
- Add disaster recovery and multi-region strategy.

## MLOps And AI SRE Extension Ideas

- AI SRE Agent: use Azure Monitor, Log Analytics, managed Prometheus, Grafana annotations, and AKS events to summarize incidents and suggest remediation.
- Drift detection: schedule Terraform plan, Checkov, OPA/Conftest, and policy-as-code checks.
- Private ML workloads: add GPU node pools, KEDA, internal model-serving ingress, private ACR, and workload identity for model artifact access.

## Cleanup

Destroy an environment only after confirming the correct backend is initialized:

```bash
bash scripts/init-dev.sh
terraform destroy -var-file=envs/dev.tfvars
```

Repeat with `qa` or `prod` only when intentional.

Remote state resources are managed by the bootstrap stack and should be destroyed separately only when all environment states are no longer needed.
