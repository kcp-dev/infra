#!/usr/bin/env bash

set -euo pipefail

cd $(dirname $0)/../..
source ../../hack/lib.sh
source hack/settings.sh
source hack/lib.sh

if [ -n "${KUBE_CONTEXT:-}" ]; then
  use_tmp_kubeconfig_context "$KUBE_CONTEXT"
fi

sed_settings 'manifests/*.yaml'

echodate "Installing Athens..."
retry 3 kubectl apply --filename manifests/athens.yaml

# create CI cluster config; this is a ConfigMap to allow different CI
# clusters to have different configuration values that are then used
# by Prow presets
retry 3 kubectl apply --filename manifests/cluster-config.yaml

###########################################################
# install additional software

echo "Enabling cgroups v2..."
kubectl apply --filename manifests/cgroups-v2-enabler.yaml

echo "Done :-)"
