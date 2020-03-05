#!/usr/bin/env bash

set -e

SECRET_NAME="$1"

if [ -z "$SECRET_NAME" ]; then
  echo "Usage: $0 [SECRET_NAME]"
  exit 1
fi

kubectl get secret $SECRET_NAME -o json | jq '.data."tls.crt"' -r | base64 -d | \
  openssl x509 -noout -subject -issuer -email -dates
