#!/usr/bin/env bash

set -e

NAME="${NAME:-$(echo $DOMAIN | tr '.' '-')-cert}"
SECRET_NAME="${SECRET_NAM:-$(echo $DOMAIN | tr '.' '-')-tls}"

while read name; do
  if [ -z "$(eval "echo \$$name")" ]; then
    echo "$name is required"
    exit 1
  fi
done <<EOF
DOMAIN
ISSUER_NAME
EOF

template=$(cat "$(dirname $0)/../manifests/certificate.yaml.tpl")
eval "echo \"$template\"" | kubectl apply -f -
