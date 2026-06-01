# Scaling Strategy

This project scales in layers: the application pods, the nginx ingress
controller, the AKS node pool, Application Gateway WAF, and shared hub security
services. Scaling decisions must keep the core security posture intact:
compute stays private, users enter only through Application Gateway, and hub to
spoke connectivity stays on VNet peering.

## Current Baseline

| Environment | AKS nodes | VM size | App replicas | Ingress path |
| --- | ---: | --- | ---: | --- |
| dev | 2 | `Standard_DC2ads_v5` | 2 | Application Gateway to private nginx ingress |
| qa | 2 | `Standard_D4s_v5` | 2 | Application Gateway to private nginx ingress |
| prod | 3 | `Standard_D4s_v5` | 2 | Application Gateway to private nginx ingress |

The hello-world chart starts with `replicaCount: 2`, CPU request `50m`, memory
request `64Mi`, CPU limit `250m`, and memory limit `256Mi`.

## Scaling Layers

### Application Pods

Scale the app first when requests increase and nodes still have spare CPU and
memory.

Recommended production direction:

- Add a Horizontal Pod Autoscaler for the `hello-world` deployment.
- Start with minimum `2` replicas and scale out based on CPU or request-rate
  metrics.
- Keep pod requests realistic so the scheduler and cluster autoscaler can make
  good placement decisions.
- Use Pod Disruption Budgets before increasing production replica count.

Manual scale example:

```bash
helm upgrade hello-world charts/hello-world \
  --namespace default \
  --reuse-values \
  --set replicaCount=4
```

### nginx Ingress Controller

nginx ingress is internal and should remain behind Application Gateway. Scale it
when Application Gateway backend health is good but ingress pods show high CPU,
memory, connection pressure, or request latency.

Recommended production direction:

- Run at least two ingress controller replicas.
- Add resource requests and limits for predictable scheduling.
- Add an HPA for the ingress controller if traffic is bursty.
- Keep the internal LoadBalancer IP fixed through `nginx_ingress_private_ip`.

### AKS Nodes

Scale nodes when pods cannot schedule or node pressure is sustained.

Current Terraform controls:

- `aks_node_count`
- `aks_vm_size`
- `aks_availability_zones`

Recommended production direction:

- Enable cluster autoscaler for the system node pool or add a separate user
  node pool with autoscaler enabled.
- Keep system workloads and application workloads separated when the platform
  grows.
- Use zone redundancy in production.
- Validate quota before increasing node count or VM size.

Manual Terraform scale example:

```hcl
aks_node_count = 4
aks_vm_size    = "Standard_D4s_v5"
```

Then run:

```bash
bash scripts/plan.sh prod
bash scripts/apply.sh prod
```

### Application Gateway WAF

Application Gateway is the public entry point and should scale before exposing
any alternative internet path. The current module uses WAF_v2 with fixed
`capacity = 2`.

Recommended production direction:

- Monitor current capacity units, throughput, connections, failed requests, and
  backend response status.
- Increase capacity when utilization remains high.
- Consider autoscale support if the module is extended to manage autoscale
  configuration instead of fixed capacity.
- Add HTTPS listeners and certificates before real production traffic.

### Azure Firewall

Azure Firewall is the default egress path for AKS and app subnets. It protects
egress, but it can also become a bottleneck if all environments share the same
hub and traffic volume grows.

Recommended production direction:

- Monitor throughput, SNAT port utilization, rule hit counts, and latency.
- Replace broad baseline egress with explicit application or FQDN rules.
- Review whether a dedicated production hub is required as traffic grows.
- Include firewall data processing in cost reviews.

### Azure Bastion

Bastion is for private administration paths, not application traffic.

Recommended production direction:

- Keep public Bastion disabled unless the approved access model requires it.
- Scale Bastion only for concurrent admin sessions.
- Prefer just-in-time and audited administrative workflows.

## Promotion Strategy

Use the same scaling change path as application and infrastructure promotion:

| Stage | Action |
| --- | --- |
| dev | Test new replica count, HPA behavior, or node sizing with synthetic traffic |
| qa | Validate latency, backend health, deployment rollback, and network controls |
| prod | Apply after review, monitor closely, and keep rollback values ready |

## Signals To Watch

| Signal | Likely scaling layer |
| --- | --- |
| Pods pending | AKS node pool |
| Pod CPU or memory sustained above target | Application pods |
| nginx ingress high CPU or request latency | nginx ingress controller |
| Application Gateway current capacity units high | Application Gateway |
| Application Gateway unhealthy backend | nginx ingress, app pods, or network path |
| Firewall SNAT or throughput pressure | Azure Firewall |
| Log Analytics ingestion spike | Diagnostics and logging configuration |

## Validation After Scaling

After any scaling change, run:

```bash
bash scripts/validate-webapp.sh "http://hello-world.local/"
python3 scripts/validate-network-controls.py --environment dev --all
```

For production, replace `dev` with the target environment and validate through
the approved DNS name or Application Gateway public IP.

Scaling is successful only when the app returns HTTP 200 through Application
Gateway, AKS compute remains private, and no direct internet path to compute is
introduced.
