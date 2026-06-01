#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-dev}"

case "${ENVIRONMENT}" in
  dev)
    DEFAULT_IP="10.10.1.100"
    ;;
  qa)
    DEFAULT_IP="10.20.1.100"
    ;;
  prod)
    DEFAULT_IP="10.30.1.100"
    ;;
  *)
    echo "Usage: $0 [dev|qa|prod]" >&2
    exit 1
    ;;
esac

export NGINX_INGRESS_PRIVATE_IP="${NGINX_INGRESS_PRIVATE_IP:-${DEFAULT_IP}}"
bash k8s/nginx-ingress/install-nginx.sh
