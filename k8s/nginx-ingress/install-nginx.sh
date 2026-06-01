#!/usr/bin/env bash
set -euo pipefail

: "${NGINX_INGRESS_PRIVATE_IP:?Set NGINX_INGRESS_PRIVATE_IP to the private IP configured in envs/<env>.tfvars.}"

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update ingress-nginx

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.replicaCount=2 \
  --set controller.ingressClass=nginx \
  --set controller.ingressClassResource.name=nginx \
  --set controller.service.loadBalancerIP="${NGINX_INGRESS_PRIVATE_IP}" \
  --set controller.service.externalTrafficPolicy=Local \
  --set-string controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-internal"="true"

kubectl -n ingress-nginx rollout status deployment/ingress-nginx-controller
