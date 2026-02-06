#!/usr/bin/env bash

# This script removes all data from the registry mirror. This is not to ensure we get fresh versions
# (in case a tagged image is updated), but more to prevent the mirror from exceeding its volume size.
# Once the script is finished, the mirror will have to re-download _everything_, leading to a slow
# Monday morning.

set -euo pipefail

cd $(dirname $0)/../..

NAMESPACE=registry

set -x

# shut down the registry mirror (deleting files while it's running actually often leads to to
# half-broken blobs, which will cause EOF errors when those images are pulled) before cleaning anything
kubectl --namespace "$NAMESPACE" scale deployment/registry-mirror --replicas 0

# create the cleanup job
kubectl create --filename manifests/registry-mirror-clean-up.yaml

# wait for it to finish
kubectl --namespace "$NAMESPACE" wait job --for "condition=complete" --selector "app=clean-up" --timeout 5m

# remove the job
kubectl --namespace "$NAMESPACE" delete job --selector "app=clean-up"

# restart the mirror
kubectl --namespace "$NAMESPACE" scale deployment/registry-mirror --replicas 1
