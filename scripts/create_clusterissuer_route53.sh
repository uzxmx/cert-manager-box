#!/usr/bin/env bash

set -e

if [ -n "$ACME_PRODUCTION" ]; then
  ISSUER_NAME="${ISSUER_NAME:-letsencrypt-route53}"
  ACME_SERVER="https://acme-v02.api.letsencrypt.org/directory"
else
  ISSUER_NAME="${ISSUER_NAME:-letsencrypt-staging-route53}"
  ACME_SERVER="https://acme-staging-v02.api.letsencrypt.org/directory"
fi

while read name; do
  if [ -z "$(eval "echo \$$name")" ]; then
    echo "$name is required"
    exit 1
  fi
done <<EOF
ISSUER_NAME
ACME_SERVER
ACME_EMAIL
AWS_REGION
AWS_ACCESS_KEY_ID
AWS_ACCESS_KEY_SECRET
AWS_ROLE
EOF

template=$(cat "$(dirname $0)/../manifests/clusterissuer-route53.yaml.tpl")
eval "echo \"$template\"" | kubectl apply -f -
