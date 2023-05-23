#!/usr/bin/env bash

# This script is meant to run as a postsubmit whenever clusters/prow/
# or prow/ changes. It is meant to then deploy every component into the
# Prow cluster.

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
echo "Preparing Helm repositories..."

helm repo add jetstack https://charts.jetstack.io
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

sed_settings 'helm-values/*.yaml'

###########################################################
echo "Installing ingress-nginx..."

deploy_helm_chart ingress-nginx ingress-nginx ingress-nginx/ingress-nginx $INGRESS_NGINX_VERSION helm-values/ingress-nginx.yaml

###########################################################
echo "Installing cert-manager..."

kubectl apply --filename https://github.com/jetstack/cert-manager/releases/download/v$CERT_MANAGER_VERSION/cert-manager.crds.yaml
deploy_helm_chart cert-manager cert-manager jetstack/cert-manager $CERT_MANAGER_VERSION helm-values/cert-manager.yaml
kubectl apply --filename manifests/clusterissuer.yaml

###########################################################
# install additional software

sed_settings 'manifests/prow/*.yaml'

echo "Installing Cluster Autoscaler..."
kubectl apply --filename manifests/cluster-autoscaler.yaml

echo "Installing Prow..."
kubectl apply --filename manifests/prow/

# must be server-side, as the YAML is way too large
kubectl replace --filename manifests/prowjob-crd.yaml

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
