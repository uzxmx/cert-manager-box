#!/usr/bin/env bash

set -e

if ! kubectl get namespace brigade &>/dev/null; then
  kubectl create namespace brigade
fi

helm repo add brigade https://brigadecore.github.io/charts

helm upgrade --install \
  brigade brigade/brigade \
  --version 1.4.2 \
  --namespace brigade

kubectl apply -f "$(dirname $0)/../manifests/brigade-worker-rbac.yaml"
