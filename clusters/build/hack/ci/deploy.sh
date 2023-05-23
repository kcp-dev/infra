#!/usr/bin/env bash

set -euo pipefail

cd $(dirname $0)/../..
source ../../hack/lib.sh
source hack/settings.sh
source hack/lib.sh

if [ -n "${KUBE_CONTEXT:-}" ]; then
  use_tmp_kubeconfig_context "$KUBE_CONTEXT"
fi

###########################################################
# setup machines

sshPubKey="$(kubectl -n kube-system get secret machine-ssh-key -o json | jq -r '.data."id_ed25519.pub" | @base64d')"
sed --in-place "s;__SSH_PUBKEY__;$sshPubKey;g" manifests/*.yaml

sed_settings 'manifests/*.yaml'

echo "Applying MachineDeployments..."
kubectl apply --filename manifests/machinedeployment-stable.yaml
kubectl apply --filename manifests/machinedeployment-worker.yaml

###########################################################
# install additional software

echo "Installing Cluster Autoscaler..."
kubectl apply --filename manifests/cluster-autoscaler.yaml

###########################################################
# ensure these deployments are scheduled on the stable nodes, so
# that when zero workers are running, these essential services still
# work

echo "Tweaking Kubermatic-managed resources..."

patch='{
  "spec": {
    "template": {
      "spec": {
        "nodeSelector": {
          "kubermatic.io/stable": "true"
        },
        "tolerations": [{
          "key": "kubermatic.io/stable",
          "operator": "Exists"
        }]
      }
    }
  }
}'

kubectl --namespace kube-system patch deployment coredns --patch "$patch"

# ensure node-local-dns runs everywhere
kubectl --namespace kube-system patch daemonset node-local-dns --patch '{
  "spec": {
    "template": {
      "spec": {
        "tolerations": [{
          "key": "kubermatic.io/stable",
          "operator": "Exists"
        }]
      }
    }
  }
}'

echo "Done :-)"
