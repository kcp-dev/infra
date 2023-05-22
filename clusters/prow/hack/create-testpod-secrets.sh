#!/usr/bin/env bash

# This script creates secrets in the cluster based on values
# from Vault. These secrets are then consumed, usually by
# defining a preset, by Prow jobs Pods.

set -euo pipefail

cd $(dirname $0)/..
source hack/settings.sh
source hack/lib.sh

##############################################
# allow tests to access the gocache

data="$(vault kv get -format=json "$VAULT_PROW_SECRET")"

generic_secret "gocache" "$PROW_TESTPOD_NAMESPACE" \
  "accessKey=$(echo "$data" | jq -r '.data.data."gocache-access-key"')" \
  "secretKey=$(echo "$data" | jq -r '.data.data."gocache-secret-key"')" \
  "address=http://minio.gocache.svc.cluster.local:9000/gocache"
