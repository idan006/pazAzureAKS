# hello-world Helm Chart

This chart deploys the `hello-world` nginx workload behind the internal nginx
ingress controller.

## Resources

The chart renders:

- `ServiceAccount`
- `Deployment`
- `Service`
- `Ingress`
- `ConfigMap` for the static homepage

## Values

Important values:

| Value | Default | Description |
| --- | --- | --- |
| `replicaCount` | `2` | Number of nginx pods |
| `image.repository` | `nginx` | Container image repository |
| `image.tag` | `stable` | Container image tag |
| `service.type` | `ClusterIP` | Kubernetes service type |
| `service.port` | `80` | Service port |
| `ingress.enabled` | `true` | Render ingress |
| `ingress.className` | `nginx` | Ingress class |
| `website.title` | `Paz-Idan` | Browser title |
| `website.heading` | `Paz-Idan` | Page heading |
| `website.message` | see `values.yaml` | Page body text |
| `resources` | see `values.yaml` | CPU and memory requests/limits |

Environment files:

- `values-dev.yaml`
- `values-qa.yaml`
- `values-prod.yaml`

## Local Validation

```bash
helm lint charts/hello-world
helm template hello-world charts/hello-world --values charts/hello-world/values-dev.yaml
```

## Install Or Upgrade

Prefer the repository wrapper script:

```bash
bash scripts/deploy-hello-world.sh dev
```

Direct Helm command:

```bash
helm upgrade --install hello-world charts/hello-world \
  --namespace default \
  --create-namespace \
  --atomic \
  --wait \
  --timeout 5m \
  --values charts/hello-world/values-dev.yaml
```

## Rollback

```bash
helm history hello-world --namespace default
helm rollback hello-world <revision> --namespace default --wait --timeout 5m
```
