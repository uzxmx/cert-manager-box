#!/usr/bin/env bash

set -e

while read name; do
  if [ -z "$(eval "echo \$$name")" ]; then
    echo "$name is required"
    exit 1
  fi
done <<EOF
PROJECT_ID
EOF

kubectl apply -f manifests/brigade-k8s-gateway-rbac.yaml

helm upgrade --install brigade-k8s-gateway \
  https://github.com/uzxmx/brigade-k8s-gateway/releases/download/v0.2.1/brigade-k8s-gateway-0.2.1.tgz \
  --namespace brigade \
  --set project="$PROJECT_ID" \
  -f "$(dirname $0)/../manifests/brigade-k8s-gateway-values.yaml"
