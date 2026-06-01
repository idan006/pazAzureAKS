# CI/CD Process

This repository uses GitHub Actions with Azure OIDC federation. No long-lived Azure credentials should be stored in GitHub.

## Required GitHub Configuration

Create GitHub Environments named `dev`, `qa`, and `prod`.

- `dev`: optional reviewer gate.
- `qa`: reviewer gate recommended.
- `prod`: required reviewers, wait timer if desired, and restricted deployment branches.

Create repository or organization secrets:

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `INFRACOST_API_KEY` for optional cost estimates.

The Azure federated credential should trust this repository and the target branch or environment subject. Use separate Azure app registrations per environment when possible.

## Workflows

- `CI - Validate IaC`: runs Terraform formatting/validation, module contract tests, Kubernetes manifest and Helm chart checks, secret scanning, Checkov, Trivy, Gitleaks, and TFLint.
- `Terraform Plan`: runs on internal pull requests for `dev`, `qa`, and `prod`, and can be manually dispatched for one environment.
- `Terraform Apply`: manually dispatched only. It creates a fresh plan, runs OPA/Conftest policy checks, then waits on the selected GitHub Environment approval before applying the exact reviewed plan artifact.
- `AKS App Deploy`: manually deploys nginx ingress and the hello-world Helm release from a self-hosted runner that can reach the private AKS API.

## Promotion Flow

1. Open a pull request.
2. CI validates static quality, security posture, secrets, Kubernetes manifests, Helm charts, and Terraform syntax.
3. Terraform Plan runs for all environments on internal PRs and uploads plan artifacts.
4. Merge after review.
5. Run `Terraform Apply` for `dev`.
6. Promote to `qa` after validation.
7. Promote to `prod` only after production environment approval.
8. Run `AKS App Deploy` from a private self-hosted runner after infrastructure is ready.

## Production Controls

- Azure authentication uses OIDC, not client secrets.
- Remote state uses Azure Storage with Azure AD authentication.
- Applies are serialized per environment using workflow concurrency.
- Production applies require GitHub Environment approval.
- OPA/Conftest policy denies unexpected public IPs, public AKS APIs, node public IPs, non-UDR AKS egress, public Key Vault access, and non-WAF Application Gateways.
- Security scans use Checkov, Trivy, and Gitleaks. CI runs them in strict mode.
- Infracost runs when `INFRACOST_API_KEY` is present.

## Private AKS Deployment Runner

The app deployment workflow must run on a self-hosted runner with labels:

```text
self-hosted
linux
aks-private
```

Place that runner in the Hub VNet or another trusted network path that can resolve and reach the private AKS API.

## Application Release Management

The `AKS App Deploy` workflow uses Helm for the application layer:

```bash
bash scripts/install-nginx-ingress.sh <environment>
bash scripts/deploy-hello-world.sh <environment>
```

The hello-world chart is stored in `charts/hello-world`. Environment-specific
settings live in `values-dev.yaml`, `values-qa.yaml`, and `values-prod.yaml`.

Use the deployment runbook for operational commands:

```text
docs/app-deployment.md
```

Related runbooks:

```text
docs/terraform-operations.md
docs/remote-state.md
docs/secret-management.md
```
