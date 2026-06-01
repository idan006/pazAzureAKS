#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib-test.sh"

require_file "k8s/hello-world/deployment.yaml"
require_file "k8s/hello-world/service.yaml"
require_file "k8s/hello-world/ingress.yaml"
require_file "k8s/nginx-ingress/install-nginx.sh"
require_file "charts/hello-world/Chart.yaml"
require_file "charts/hello-world/values.yaml"
require_file "charts/hello-world/templates/configmap.yaml"
require_file "charts/hello-world/templates/deployment.yaml"
require_file "charts/hello-world/templates/service.yaml"
require_file "charts/hello-world/templates/ingress.yaml"

require_pattern "k8s/hello-world/deployment.yaml" "image:[[:space:]]*nginx:stable" "hello-world deployment uses nginx:stable"
require_pattern "k8s/hello-world/deployment.yaml" "replicas:[[:space:]]*2" "hello-world deployment has two replicas"
require_pattern "k8s/hello-world/deployment.yaml" "readinessProbe:" "hello-world deployment has readiness probe"
require_pattern "k8s/hello-world/deployment.yaml" "livenessProbe:" "hello-world deployment has liveness probe"
require_pattern "k8s/hello-world/service.yaml" "type:[[:space:]]*ClusterIP" "hello-world service is ClusterIP"
require_pattern "k8s/hello-world/ingress.yaml" "ingressClassName:[[:space:]]*nginx" "hello-world ingress uses nginx class"
require_pattern "k8s/hello-world/ingress.yaml" "path:[[:space:]]*/" "hello-world ingress exposes root path"
require_pattern "k8s/nginx-ingress/install-nginx.sh" "azure-load-balancer-internal" "nginx ingress load balancer is internal"
require_pattern "k8s/nginx-ingress/install-nginx.sh" "controller\\.service\\.loadBalancerIP" "nginx ingress pins the private load balancer IP"
require_pattern "charts/hello-world/Chart.yaml" "apiVersion:[[:space:]]*v2" "hello-world Helm chart uses chart API v2"
require_pattern "charts/hello-world/values.yaml" "replicaCount:[[:space:]]*2" "hello-world Helm chart defaults to two replicas"
require_pattern "charts/hello-world/values.yaml" "Paz-Idan" "hello-world Helm chart sets Paz-Idan website name"
require_pattern "charts/hello-world/templates/configmap.yaml" "index\\.html" "hello-world Helm chart renders static website content"
require_pattern "charts/hello-world/templates/deployment.yaml" "readinessProbe:" "hello-world Helm deployment has readiness probe"
require_pattern "charts/hello-world/templates/deployment.yaml" "livenessProbe:" "hello-world Helm deployment has liveness probe"
require_pattern "charts/hello-world/templates/service.yaml" "type:[[:space:]]*\\{\\{" "hello-world Helm service type is configurable"
require_pattern "charts/hello-world/templates/ingress.yaml" "ingressClassName:" "hello-world Helm ingress sets class"

if command -v python3 >/dev/null 2>&1 && python3 -c "import yaml" >/dev/null 2>&1; then
  python3 - <<'PY'
from pathlib import Path
import sys
import yaml

expected = {
    "k8s/hello-world/deployment.yaml": "Deployment",
    "k8s/hello-world/service.yaml": "Service",
    "k8s/hello-world/ingress.yaml": "Ingress",
}

for path, kind in expected.items():
    documents = [doc for doc in yaml.safe_load_all(Path(path).read_text()) if doc]
    if len(documents) != 1:
        print(f"{path}: expected exactly one YAML document", file=sys.stderr)
        sys.exit(1)
    actual_kind = documents[0].get("kind")
    if actual_kind != kind:
        print(f"{path}: expected kind {kind}, got {actual_kind}", file=sys.stderr)
        sys.exit(1)
PY
  pass "YAML parser validates hello-world manifest structure"
else
  echo "SKIP: python3 with PyYAML is not installed; static manifest checks completed."
fi

if command -v helm >/dev/null 2>&1; then
  helm lint charts/hello-world >/dev/null
  helm template hello-world charts/hello-world --values charts/hello-world/values-dev.yaml >/tmp/hello-world-rendered.yaml
  require_pattern "/tmp/hello-world-rendered.yaml" "kind:[[:space:]]*Deployment" "Helm template renders Deployment"
  require_pattern "/tmp/hello-world-rendered.yaml" "kind:[[:space:]]*ConfigMap" "Helm template renders ConfigMap"
  require_pattern "/tmp/hello-world-rendered.yaml" "Paz-Idan" "Helm template renders Paz-Idan content"
  require_pattern "/tmp/hello-world-rendered.yaml" "kind:[[:space:]]*Service" "Helm template renders Service"
  require_pattern "/tmp/hello-world-rendered.yaml" "kind:[[:space:]]*Ingress" "Helm template renders Ingress"
  pass "Helm lint and template validate hello-world chart"
else
  echo "SKIP: helm is not installed; chart lint skipped."
fi

if command -v kubectl >/dev/null 2>&1 && kubectl cluster-info --request-timeout=3s >/dev/null 2>&1; then
  kubectl apply --dry-run=server -f k8s/hello-world/deployment.yaml >/dev/null
  kubectl apply --dry-run=server -f k8s/hello-world/service.yaml >/dev/null
  kubectl apply --dry-run=server -f k8s/hello-world/ingress.yaml >/dev/null
  pass "kubectl server-side dry-run validates hello-world manifests"
elif command -v kubectl.exe >/dev/null 2>&1 && kubectl.exe cluster-info --request-timeout=3s >/dev/null 2>&1; then
  kubectl.exe apply --dry-run=server -f k8s/hello-world/deployment.yaml >/dev/null
  kubectl.exe apply --dry-run=server -f k8s/hello-world/service.yaml >/dev/null
  kubectl.exe apply --dry-run=server -f k8s/hello-world/ingress.yaml >/dev/null
  pass "kubectl server-side dry-run validates hello-world manifests"
else
  echo "SKIP: no reachable Kubernetes API; server-side manifest dry-run skipped."
fi

finish_tests
