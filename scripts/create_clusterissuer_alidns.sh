#!/usr/bin/env bash

set -e

if [ -n "$ACME_PRODUCTION" ]; then
  ISSUER_NAME="letsencrypt-alidns"
  ACME_SERVER="https://acme-v02.api.letsencrypt.org/directory"
else
  ISSUER_NAME="letsencrypt-staging-alidns"
  ACME_SERVER="https://acme-staging-v02.api.letsencrypt.org/directory"
fi

GROUP_NAME="${GROUP_NAME:-example.com}"

while read name; do
  if [ -z "$(eval "echo \$$name")" ]; then
    echo "$name is required"
    exit 1
  fi
done <<EOF
ISSUER_NAME
ACME_SERVER
GROUP_NAME
ACME_EMAIL
ALIDNS_ACCESS_KEY_ID
ALIDNS_ACCESS_KEY_SECRET
EOF

template=$(cat "$(dirname $0)/../manifests/clusterissuer-alidns.yaml.tpl")
eval "echo \"$template\"" | kubectl apply -f -
