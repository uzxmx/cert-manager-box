#!/usr/bin/env bash

set -e

kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/v0.12.0/deploy/manifests/00-crds.yaml

if ! kubectl get namespace cert-manager &>/dev/null; then
  kubectl create namespace cert-manager
fi

helm repo add jetstack https://charts.jetstack.io

helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v0.12.0 \
  --set image.repository="quay.azk8s.cn/jetstack/cert-manager-controller" \
  --set webhook.image.repository="quay.azk8s.cn/jetstack/cert-manager-webhook" \
  --set cainjector.image.repository="quay.azk8s.cn/jetstack/cert-manager-cainjector"
