#!/usr/bin/env bash

set -e

helm upgrade --install \
  alidns https://github.com/uzxmx/cert-manager-webhook-alidns/releases/download/v0.1.0/alidns-0.1.0.tgz \
  --namespace cert-manager \
  --set groupName="${GROUP_NAME:-example.com}" \
  --set image.repository=dockerhub.azk8s.cn/uzxmx/cert-manager-webhook-alidns
