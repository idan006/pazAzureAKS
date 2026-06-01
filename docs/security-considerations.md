# Security Considerations

This architecture protects the `Paz-Idan` workload by keeping compute private
and forcing all public application traffic through controlled security layers.

## Public Exposure

The only public application entry point is Azure Application Gateway WAF.
Application Gateway receives internet traffic, applies WAF protections, and
forwards approved requests to the private nginx ingress IP inside the spoke VNet.

AKS does not expose a public API endpoint, AKS nodes do not have public IPs, and
the Kubernetes ingress controller uses an internal Azure Load Balancer only.

## Network Isolation

The workload runs in a private spoke VNet. The hub and spoke VNets communicate
through VNet peering only. Spoke subnet NSGs deny inbound internet traffic, so
internet clients cannot connect directly to pods, nodes, services, or private
endpoints.

AKS and app subnet egress use a User Defined Route that sends default traffic to
Azure Firewall. This centralizes outbound inspection and control.

## Application Protection

Application Gateway WAF protects the public HTTP path before traffic reaches the
cluster. nginx ingress then routes traffic internally to the `hello-world`
ClusterIP service, which load balances to the `Paz-Idan` nginx pods.

The app is deployed with Helm, giving controlled upgrades, rollbacks, and
repeatable release configuration.

## Secret Protection

Key Vault is deployed with public network access disabled, purge protection,
soft delete, RBAC authorization, diagnostics, a private endpoint, and private
DNS. Secrets should be accessed through managed identity or workload identity
patterns rather than committed into Terraform, Helm values, or Kubernetes
manifests.

## Operational Guardrails

The repository includes checks for:

- private AKS API
- no AKS node public IPs
- Azure CNI and Azure Network Policy
- UDR egress through Azure Firewall
- spoke NSG deny-internet rules
- Application Gateway WAF usage
- Key Vault private access controls
- no obvious committed secrets

Use this validation command after deployment:

```bash
python3 scripts/validate-network-controls.py --environment dev --all
```

## Remaining Hardening Items

Before production, add HTTPS listeners and certificates, tune WAF rules for the
application, replace broad firewall egress with explicit allow rules, enforce
Azure Policy initiatives, add workload identity bindings for real applications,
and configure monitoring alerts and incident response runbooks.
