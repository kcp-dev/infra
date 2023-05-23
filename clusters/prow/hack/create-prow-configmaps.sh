#!/usr/bin/env bash

# This script can be used for the initial setup of Prow ConfigMaps.
# Once Prow is up and running, its config_updater plugin will keep
# the ConfigMaps up-to-date.

set -euo pipefail

cd $(dirname $0)/..
source hack/settings.sh
source hack/lib.sh

PROW_DIR="$(realpath ../../prow)"

# configure prow itself
kubectl --namespace "$PROW_NAMESPACE" create configmap config \
  --from-file="config.yaml=$PROW_DIR/config.yaml" \
  --dry-run=client \
  --output=yaml \
  | kubectl apply -f -

# ... and its plugins
kubectl --namespace "$PROW_NAMESPACE" create configmap plugins \
  --from-file="plugins.yaml=$PROW_DIR/plugins.yaml" \
  --dry-run=client \
  --output=yaml \
  | kubectl apply -f -

# ... and its global jobs
create_job_config_configmap "$PROW_DIR"
kubectl replace -f job-config.yaml
