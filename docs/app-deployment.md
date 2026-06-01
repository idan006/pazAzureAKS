# Application Deployment Runbook

This runbook covers the Kubernetes application layer for the private AKS platform.
Terraform owns Azure infrastructure. Helm owns the `hello-world` application release.

## Ownership Boundary

| Layer | Owner | Examples |
| --- | --- | --- |
| Azure infrastructure | Terraform | Resource group, VNets, AKS, App Gateway, Firewall, Key Vault, remote state |
| Ingress controller | Helm upstream chart | `ingress-nginx/ingress-nginx` installed by `scripts/install-nginx-ingress.sh` |
| Application workload | Local Helm chart | `charts/hello-world` installed by `scripts/deploy-hello-world.sh` |

Do not manage the same Kubernetes workload with both raw `kubectl apply` and Helm.
The raw manifests under `k8s/hello-world/` are kept as a simple reference, but the
production deployment path is the Helm chart under `charts/hello-world/`.

## Prerequisites

Run app commands from a host that can reach the private AKS API:

- A private self-hosted GitHub runner with the `aks-private` label
- A VM in the hub or spoke VNet
- A VPN-connected workstation
- An ExpressRoute-connected host

Required tools:

- Azure CLI
- kubectl
- Helm 3

Authenticate and get private AKS credentials:

```bash
az login
az account set --subscription "<subscription-id>"

az aks get-credentials \
  --resource-group azure-hub-spoke-aks-dev-rg \
  --name azure-hub-spoke-aks-dev-aks \
  --overwrite-existing
```

## Install Or Upgrade nginx Ingress

Install the internal nginx ingress controller:

```bash
bash scripts/install-nginx-ingress.sh dev
```

Default private load balancer IPs:

| Environment | IP |
| --- | --- |
| dev | `10.10.1.100` |
| qa | `10.20.1.100` |
| prod | `10.30.1.100` |

Override the IP when needed:

```bash
NGINX_INGRESS_PRIVATE_IP=10.10.1.100 bash scripts/install-nginx-ingress.sh dev
```

Verify ingress:

```bash
kubectl -n ingress-nginx rollout status deployment/ingress-nginx-controller
kubectl -n ingress-nginx get svc ingress-nginx-controller -o wide
```

The service should show the environment private IP in `EXTERNAL-IP`.

## Deploy hello-world With Helm

Deploy the application:

```bash
bash scripts/deploy-hello-world.sh dev
```

The script runs:

```bash
helm upgrade --install hello-world charts/hello-world \
  --namespace default \
  --create-namespace \
  --atomic \
  --wait \
  --timeout 5m \
  --values charts/hello-world/values-dev.yaml
```

Environment values files:

| Environment | Values file |
| --- | --- |
| dev | `charts/hello-world/values-dev.yaml` |
| qa | `charts/hello-world/values-qa.yaml` |
| prod | `charts/hello-world/values-prod.yaml` |

Useful optional overrides:

```bash
HELM_RELEASE_NAME=hello-world \
HELM_NAMESPACE=default \
CHART_PATH=charts/hello-world \
bash scripts/deploy-hello-world.sh dev
```

## Validate A Release

Check Helm status:

```bash
helm status hello-world --namespace default
helm history hello-world --namespace default
```

Check Kubernetes resources:

```bash
kubectl get deploy,po,svc,ingress --namespace default -o wide
kubectl rollout status deployment/hello-world --namespace default
```

Expected healthy state:

- Helm release status is `deployed`
- `deployment/hello-world` is `2/2` in dev and qa
- `deployment/hello-world` is `3/3` in prod
- `ingress/hello-world` address matches the nginx ingress private IP
- Application Gateway backend health is `Healthy`
- Public endpoint returns HTTP 200

Validate through Application Gateway:

```bash
PUBLIC_IP="$(terraform output -raw application_gateway_public_ip)"
bash scripts/validate-webapp.sh "http://${PUBLIC_IP}/"
```

Validate with a workstation hosts entry:

```text
<application-gateway-public-ip> hello-world.local # paz-hello-world
```

Then run:

```bash
bash scripts/validate-webapp.sh http://hello-world.local/
curl --noproxy '*' -I http://hello-world.local/
```

## Roll Back

List release revisions:

```bash
helm history hello-world --namespace default
```

Roll back to a previous revision:

```bash
helm rollback hello-world <revision> --namespace default --wait --timeout 5m
kubectl rollout status deployment/hello-world --namespace default
```

Validate HTTP 200 after rollback:

```bash
bash scripts/validate-webapp.sh http://hello-world.local/
```

## Uninstall The App

Use uninstall only when intentionally removing the workload while keeping AKS:

```bash
helm uninstall hello-world --namespace default
```

This removes the app deployment, service, and ingress. It does not remove AKS,
nginx ingress, Application Gateway, or any Azure infrastructure.

## Troubleshooting

If `helm upgrade --install` times out:

```bash
helm status hello-world --namespace default
kubectl get pods --namespace default -l app.kubernetes.io/name=hello-world -o wide
kubectl describe pods --namespace default -l app.kubernetes.io/name=hello-world
kubectl logs --namespace default -l app.kubernetes.io/name=hello-world --tail=100 --previous
```

If Application Gateway returns `502`:

```bash
az network application-gateway show-backend-health \
  --resource-group azure-hub-spoke-aks-dev-rg \
  --name azure-hub-spoke-aks-dev-agw \
  --query 'backendAddressPools[].backendHttpSettingsCollection[].servers[].{address:address,health:health,healthProbeLog:healthProbeLog}' \
  --output table
```

Then confirm nginx ingress has the expected private IP:

```bash
kubectl -n ingress-nginx get svc ingress-nginx-controller -o wide
kubectl get ingress hello-world --namespace default -o wide
```

If the nginx ingress `EXTERNAL-IP` stays pending and events show Azure RBAC
`AuthorizationFailed`, confirm the AKS control plane identity has
`Network Contributor` on the spoke VNet and AKS subnet, then allow Azure RBAC
propagation time.

## Chart Security Notes

The chart drops all Linux capabilities and adds back only the capabilities
required by the stock `nginx:stable` image to start as root and bind port 80:

- `CHOWN`
- `SETGID`
- `SETUID`
- `NET_BIND_SERVICE`

For a stricter production container, use an nginx image designed to run as a
non-root user on an unprivileged port, then update the chart values accordingly.
