#!/usr/bin/env bash

# This script provisions the kcp CI cluster.
#
# In case you need to run this without the Captain cluster,
# set `CLUSTER_KUBECONFIG` env variable to the kubeconfig
# of the target cluster. This will skip fetching the kubeconfig
# from the Captain. It's different from `KUBECONFIG` simply
# to prevent accidents by fat-fingering the script.
#
# Vault can be skipped entirely by _also_ setting `SSH_PUBKEY_FILE`
# for the SSH key that is put on all machines.
# Additionally, you need to provide the following secrets manually:
#
#    * GOCACHE_ACCESS_KEY
#    * GOCACHE_SECRET_KEY

set -euo pipefail

cd $(dirname $0)/../..
source ../../hack/lib.sh
source hack/settings.sh
source hack/lib.sh

if ! vault_is_logged_in; then
  if [ -z "${CLUSTER_KUBECONFIG:-}" ] || [ -z "${SSH_PUBKEY_FILE:-}" ] || [ -z "${GOCACHE_ACCESS_KEY:-}" ] || [ -z "${GOCACHE_SECRET_KEY:-}" ]; then
    echodate "Logging into Vault..."
    vault_login
  fi
fi

if [ -z "${SSH_PUBKEY_FILE:-}" ]; then
  vault kv get -field=id_ed25519.pub "$VAULT_CLUSTER_SECRET" > id_ed25519.pub
  export SSH_PUBKEY_FILE="$(realpath id_ed25519.pub)"
else
  echodate "Using $SSH_PUBKEY_FILE as SSH public key file for workers..."
fi

if [ -z "${GOCACHE_ACCESS_KEY:-}" ] || [ -z "${GOCACHE_SECRET_KEY:-}" ]; then
  keys="$(vault kv get -format=json "$VAULT_PROW_SECRET")"

  export GOCACHE_ACCESS_KEY="${GOCACHE_ACCESS_KEY:-$(echo "$keys" | jq -r '.data.data."gocache-access-key"')}"
  export GOCACHE_SECRET_KEY="${GOCACHE_SECRET_KEY:-$(echo "$keys" | jq -r '.data.data."gocache-secret-key"')}"
fi

###########################################################
# prepare kubeconfig

if [ -z "${CLUSTER_KUBECONFIG:-}" ]; then
  # get KKP Service Account token
  echodate "Retrieving Service Account from Vault..."

  vault kv get -field=kubeconfig "$VAULT_CLUSTER_SECRET" > old.kubeconfig
  KKP_TOKEN="$(vault kv get -field=kubermatic-token "$VAULT_CLUSTER_SECRET")"

  # get cluster kubeconfig live from KKP
  curl \
    --header "Authorization: Bearer $KKP_TOKEN" \
    https://captain.k8c.io/api/v1/projects/$PROJECT_ID/dc/captain/clusters/$CLUSTER_ID/kubeconfig \
    > cluster.kubeconfig

  export KUBECONFIG=$(realpath cluster.kubeconfig)

  # update kubeconfig in Vault, for consumption by devs without access to
  # the captain cluster
  if ! diff $KUBECONFIG old.kubeconfig > /dev/null; then
    echodate "Updating kubeconfig in Vault..."
    vault kv patch "$VAULT_CLUSTER_SECRET" kubeconfig=@$KUBECONFIG
  fi
else
  echodate "Using $CLUSTER_KUBECONFIG as KUBECONFIG..."
  export KUBECONFIG="$CLUSTER_KUBECONFIG"
fi

# Helm issues lots of warnings if the kubeconfig is group/world readable
chmod 600 "$KUBECONFIG"

###########################################################
# setup machines

sed_settings 'manifests/*.yaml'

SSH_PUBKEY="$(cat "$SSH_PUBKEY_FILE")"
sed --in-place "s;__SSH_PUBKEY__;$SSH_PUBKEY;g" manifests/*.yaml

echodate "Applying MachineDeployments..."
retry 3 kubectl apply --filename manifests/machinedeployment-stable.yaml
retry 3 kubectl apply --filename manifests/machinedeployment-worker.yaml

###########################################################
echodate "Preparing Helm repositories..."

helm repo add jetstack https://charts.jetstack.io
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add minio https://charts.min.io/
helm repo update

deploy() {
  local namespace="$1"
  local release="$2"
  local chart="$3"
  local version="$4"
  local valuesFile="$5"

  retry 3 helm --namespace "$namespace" upgrade \
    --install \
    --create-namespace \
    --values "$valuesFile" \
    --version $version \
    "$release" "$chart"
}

sed_settings 'helm-values/*.yaml'

###########################################################
echodate "Installing ingress-nginx..."

deploy ingress-nginx ingress-nginx ingress-nginx/ingress-nginx $INGRESS_NGINX_VERSION helm-values/ingress-nginx.yaml

###########################################################
echodate "Installing cert-manager..."

retry 3 kubectl apply --filename https://github.com/jetstack/cert-manager/releases/download/v$CERT_MANAGER_VERSION/cert-manager.crds.yaml
deploy cert-manager cert-manager jetstack/cert-manager $CERT_MANAGER_VERSION helm-values/cert-manager.yaml
retry 3 kubectl apply --filename manifests/clusterissuer.yaml

###########################################################
echodate "Installing Minio Gocache..."

yq --inplace '.rootUser=env(GOCACHE_ACCESS_KEY)' helm-values/minio-gocache.yaml
yq --inplace '.rootPassword=env(GOCACHE_SECRET_KEY)' helm-values/minio-gocache.yaml

deploy gocache minio minio/minio $MINIO_VERSION helm-values/minio-gocache.yaml

# truly wait until Minio is ready
echodate "Preparing Gocache access..."
kubectl --namespace gocache wait --for=condition=Ready --selector 'app=minio' pod
kubectl --namespace gocache port-forward svc/minio 9000 > /dev/null &
retry 5 curl -s http://127.0.0.1:9000 > /dev/null

# create buckets
echodate "Ensuring public gocache bucket..."
mc config host add gocache http://127.0.0.1:9000 "$GOCACHE_ACCESS_KEY" "$GOCACHE_SECRET_KEY"
mc mb --ignore-existing gocache/gocache
mc policy set public gocache/gocache
kill_port_forwardings 9000

###########################################################
# ensure these deployments are scheduled on the stable nodes, so
# that when zero workers are running, these essential services still
# work

echodate "Tweaking Kubermatic-managed resources..."

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

###########################################################
# install additional software

echodate "Installing Cluster Autoscaler..."
retry 3 kubectl apply --filename manifests/cluster-autoscaler.yaml

echodate "Installing node reaper..."
retry 3 kubectl apply --filename manifests/node-reaper.yaml

echodate "Installing Athens..."
retry 3 kubectl apply --filename manifests/athens.yaml

echodate "Installing Docker Registry mirror..."
retry 3 kubectl apply --filename manifests/registry-mirror.yaml

echodate "Applying additional manifests..."
retry 3 kubectl apply --filename manifests/multiarch-deps-installer.yaml

# create CI cluster config; this is a ConfigMap to allow different CI
# clusters to have different configuration values that are then used
# by Prow presets
retry 3 kubectl apply --filename manifests/cluster-config.yaml

echodate "Installing Prow..."

sed_settings 'manifests/prow/*.yaml'
retry 3 kubectl apply --filename manifests/prow/

# must be server-side, as the YAML is way too large
retry 3 kubectl replace --filename manifests/prowjob-crd.yaml

echodate "Done :-)"
