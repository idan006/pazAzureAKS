#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-dev}"
RELEASE_NAME="${HELM_RELEASE_NAME:-hello-world}"
NAMESPACE="${HELM_NAMESPACE:-default}"
CHART_PATH="${CHART_PATH:-charts/hello-world}"
VALUES_FILE="${CHART_PATH}/values-${ENVIRONMENT}.yaml"

case "${ENVIRONMENT}" in
  dev|qa|prod)
    ;;
  *)
    echo "Usage: $0 [dev|qa|prod]" >&2
    exit 1
    ;;
esac

helm_args=(
  upgrade
  --install
  "${RELEASE_NAME}"
  "${CHART_PATH}"
  --namespace "${NAMESPACE}"
  --create-namespace
  --atomic
  --wait
  --timeout 5m
)

if [[ -f "${VALUES_FILE}" ]]; then
  helm_args+=(--values "${VALUES_FILE}")
fi

for resource in deployment/hello-world service/hello-world ingress/hello-world; do
  if kubectl get "${resource}" --namespace "${NAMESPACE}" >/dev/null 2>&1; then
    kubectl annotate "${resource}" \
      --namespace "${NAMESPACE}" \
      "meta.helm.sh/release-name=${RELEASE_NAME}" \
      "meta.helm.sh/release-namespace=${NAMESPACE}" \
      --overwrite
    kubectl label "${resource}" \
      --namespace "${NAMESPACE}" \
      app.kubernetes.io/managed-by=Helm \
      --overwrite
  fi
done

helm "${helm_args[@]}"
kubectl rollout status "deployment/${RELEASE_NAME}" --namespace "${NAMESPACE}" --timeout=180s
