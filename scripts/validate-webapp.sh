#!/usr/bin/env bash
set -euo pipefail

PUBLIC_URL="${1:-}"

if [[ -z "${PUBLIC_URL}" ]]; then
  echo "Usage: $0 <http://application-gateway-public-ip-or-dns-name/>" >&2
  exit 1
fi

HTTP_STATUS="$(curl -ksS -o /tmp/hello-world-response.txt -w "%{http_code}" "${PUBLIC_URL}")"

if [[ "${HTTP_STATUS}" != "200" ]]; then
  echo "Expected HTTP 200 from ${PUBLIC_URL}, got ${HTTP_STATUS}." >&2
  cat /tmp/hello-world-response.txt >&2 || true
  exit 1
fi

echo "HTTP 200 OK from ${PUBLIC_URL}"
