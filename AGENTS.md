# Agent Notes

This repository deploys an Azure hub-spoke AKS platform with Terraform.

Use the project scripts for normal operations:

- `scripts/bootstrap-state.sh` for remote state bootstrap.
- `scripts/init-dev.sh`, `scripts/init-qa.sh`, or `scripts/init-prod.sh` for backend initialization.
- `scripts/plan.sh <environment>` followed by `scripts/apply.sh <environment>` for infrastructure changes.
- `scripts/install-nginx-ingress.sh <environment>` and `scripts/deploy-hello-world.sh` for the sample AKS workload.
- `scripts/validate-all.sh` for local validation.

Do not commit secrets or real credentials. Keep environment-specific values in `envs/*.tfvars` and backend settings in `backend/*.backend.hcl`.
