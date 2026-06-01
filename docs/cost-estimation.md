# Cost Estimation

This document estimates monthly Azure costs for the current hub-spoke private
AKS design in East US. Estimates use public pay-as-you-go retail rates and
730 hours per month. Actual billing can differ because of discounts,
reservations, savings plans, traffic volume, logs, currency, taxes, and future
Azure price changes.

Pricing references:

- Azure Retail Prices API: https://learn.microsoft.com/en-us/rest/api/cost-management/retail-prices/azure-retail-prices
- Azure Pricing Calculator: https://azure.microsoft.com/pricing/calculator/
- Application Gateway pricing model: https://learn.microsoft.com/azure/application-gateway/understanding-pricing
- Azure Bastion cost optimization: https://learn.microsoft.com/azure/bastion/cost-optimization

## Estimate Assumptions

| Item | Assumption |
| --- | --- |
| Region | East US |
| Currency | USD |
| Hours | 730 hours per month |
| AKS control plane | Free tier, no paid uptime SLA |
| AKS OS disks | One 128 GiB managed OS disk per node, estimated as P10 LRS |
| Application Gateway | WAF_v2, fixed capacity `2`, equivalent to 20 billable capacity units |
| Azure Firewall | Standard deployment plus one capacity unit, no data processing included |
| Azure Bastion | Premium SKU, `2` scale units, no outbound data transfer included |
| Key Vault | Standard SKU, 10K operations per month |
| Private Link | One Key Vault private endpoint, no data processing included |
| Log Analytics | Dev/QA: 5 GB ingestion per month, Prod: 10 GB ingestion per month |
| Terraform state storage | Hot LRS blob storage with low operation volume |

## Monthly Estimate By Environment

| Resource | Dev | QA | Prod |
| --- | ---: | ---: | ---: |
| AKS Linux node VMs | $150.38 | $280.32 | $420.48 |
| AKS node OS disks | $39.42 | $39.42 | $59.13 |
| Application Gateway WAF_v2 | $473.04 | $473.04 | $473.04 |
| Azure Firewall Standard | $963.60 | $963.60 | $963.60 |
| Azure Bastion Premium | $328.50 | $328.50 | $328.50 |
| Standard public IPs | $7.30 | $3.65 | $3.65 |
| Key Vault private endpoint | $7.30 | $7.30 | $7.30 |
| Key Vault operations | $0.03 | $0.03 | $0.03 |
| Log Analytics ingestion | $11.50 | $11.50 | $23.00 |
| Terraform state storage | $0.10 | $0.10 | $0.10 |
| **Estimated monthly total** | **$1,981.17** | **$2,107.46** | **$2,278.83** |

## Shared Remote State Cost

The Terraform remote state storage account is shared by the environments.
For normal state files and backups, the cost should stay very small. The table
above shows `$0.10` per environment for visibility, but the real bill normally
appears once for the shared state storage account.

## Variable Costs Not Included

The following costs depend on workload behavior and are not included in the
fixed monthly totals:

- Azure Firewall data processed.
- Application Gateway outbound data transfer.
- Private Link data processed.
- VNet peering ingress and egress data transfer.
- Log Analytics ingestion above the assumed monthly volume.
- Diagnostic logs for Application Gateway, Firewall, Bastion, Key Vault, and
  AKS if additional categories are enabled.
- DNS query volume for Private DNS zones.
- Defender for Cloud plans if the current placeholders are converted into
  enabled paid plans.

## Cost Drivers

The largest steady-state cost drivers are Azure Firewall, Application Gateway
WAF_v2, Azure Bastion Premium, and AKS node VMs. For non-production
environments, the fastest cost reduction options are:

- Stop or destroy idle environments.
- Lower `aks_node_count` when the environment is not actively tested.
- Use smaller AKS node sizes when workload capacity allows it.
- Review whether Premium Bastion is required in every environment.
- Keep Log Analytics ingestion and diagnostic categories controlled.

## Review Cadence

Review this estimate before every production architecture change and after
changes to these settings:

- `aks_node_count`
- `aks_vm_size`
- Application Gateway `capacity`
- Bastion `sku` or `scale_units`
- Firewall SKU/tier
- Log Analytics retention or diagnostic volume
- New private endpoints, public IPs, or data-heavy services

CI already includes optional Infracost support in the Terraform plan workflow.
Use that for pull-request level deltas, and use this document as the baseline
monthly run-rate estimate.
