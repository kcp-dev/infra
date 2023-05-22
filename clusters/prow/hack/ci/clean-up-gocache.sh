#!/usr/bin/env bash

# This script cleans up the Gocache-Minio instance running in the gocache
# namespace. The files in the "gocache" bucket are grouped per repo and
# branch:
#
#  /
#  /kubermatic
#    /main
#      /<sha1>-<goversion>-<GOARCH>.tar
#    /release-v2.17
#    /release-v2.16
#  /machine-controller
#    /main
#
# The goal is to delete all but the most recent N archives for each
# repo+branch combination.
#
# This script is supposed to be run in the kcp-ci cluster, however
# it can also be used standalone, for example, on a local computer.
#
# The script uses the following environment variables:
#   * GOCACHE_MINIO_ADDRESS (defaults to http://127.0.0.1:9000/gocache, note the added bucket name!)
#   * GOCACHE_ACCESS_KEY
#   * GOCACHE_SECRET_KEY
#   * CLUSTER_KUBECONFIG (the kubeconfig for the cluster where Minio is running)
#   * CLUSTER_NAME (to check if the script is running in-cluster)
#
# If any of those environment variables are not provided, the script will try
# to obtain them from Vault.

set -euo pipefail

cd $(dirname $0)/../..
source ../../hack/lib.sh
source hack/settings.sh

export GOCACHE_MINIO_ADDRESS=${GOCACHE_MINIO_ADDRESS:-http://127.0.0.1:9000/gocache}

# do not set this too low, or else if a repo uses multiple Go versions (for
# some reason, usually only during prewarms before introducing a new Go version)
# or (more realistically) multiple architectures, we might delete too many files
export FILES_TO_KEEP=10

# split apart the address into base and bucket; the reason
# the bucket is in the URL at all is that we consume the
# default preset from Prow and that has GOCACHE_MINIO_ADDRESS
# with a bucket, so that Prowjobs don't need to know the
# bucket. This is beautiful for everything but this script. ^^
export GOCACHE_BUCKET=$(basename "$GOCACHE_MINIO_ADDRESS")
export GOCACHE_MINIO_ADDRESS=$(dirname "$GOCACHE_MINIO_ADDRESS")

if ! vault_is_logged_in; then
  if [[ -z "${CLUSTER_KUBECONFIG:-}" && -z "${CLUSTER_NAME:-}" ]] || [ -z "${GOCACHE_ACCESS_KEY:-}" ] || [ -z "${GOCACHE_SECRET_KEY:-}" ]; then
    echodate "Logging into Vault..."
    vault_login
  fi
fi

if [ -z "${GOCACHE_ACCESS_KEY:-}" ] || [ -z "${GOCACHE_SECRET_KEY:-}" ]; then
  keys="$(vault kv get -format=json "$VAULT_PROW_SECRET")"

  export GOCACHE_ACCESS_KEY="${GOCACHE_ACCESS_KEY:-$(echo "$keys" | jq -r '.data.data."gocache-access-key"')}"
  export GOCACHE_SECRET_KEY="${GOCACHE_SECRET_KEY:-$(echo "$keys" | jq -r '.data.data."gocache-secret-key"')}"
fi

# if the CLUSTER_NAME variable is set, assume that we're running in-cluster.
# in that case we don't need the kubeconfig, because we can access minio
# directly
if [ -z "${CLUSTER_NAME:-}" ]; then
  if [ -z "${CLUSTER_KUBECONFIG:-}" ]; then
    # get KKP Service Account token
    echodate "Retrieving Service Account from Vault..."

    KKP_TOKEN="$(vault kv get -field=kubermatic-token "$VAULT_CLUSTER_SECRET")"

    # get cluster kubeconfig live from KKP
    curl \
      --header "Authorization: Bearer $KKP_TOKEN" \
      https://captain.k8c.io/api/v1/projects/$PROJECT_ID/dc/captain/clusters/$CLUSTER_ID/kubeconfig \
      > cluster.kubeconfig

    export KUBECONFIG=$(realpath cluster.kubeconfig)
  else
    echodate "Using $CLUSTER_KUBECONFIG as KUBECONFIG..."
    export KUBECONFIG="$CLUSTER_KUBECONFIG"
  fi

  echodate "Preparing Gocache access..."
  kubectl --namespace gocache wait --for=condition=Ready --selector 'app=minio' pod
  kubectl --namespace gocache port-forward svc/minio 9000 > /dev/null &
  trap "kill_port_forwardings 9000" EXIT
else
  echodate "CLUSTER_NAME is set to $CLUSTER_NAME, assuming script is running in-cluster"
fi

# wait for Minio to be ready
retry 5 curl -s "$GOCACHE_MINIO_ADDRESS" > /dev/null

# clean-up buckets
echodate "Cleaning up bucket..."
mc config host add gocache "$GOCACHE_MINIO_ADDRESS" "$GOCACHE_ACCESS_KEY" "$GOCACHE_SECRET_KEY"

repositories="$(mc ls "gocache/$GOCACHE_BUCKET/" --json | jq -r 'select(.type=="folder").key')"

while read -r repo; do
  branches="$(mc ls "gocache/$GOCACHE_BUCKET/$repo" --json | jq -r 'select(.type=="folder").key')"

  while read -r branch; do
    files="$(mc ls "gocache/$GOCACHE_BUCKET/$repo$branch" --json | jq -s -r '. | sort_by(.lastModified) | .[].key' | head -n-$FILES_TO_KEEP)"

    if [ -n "$files" ]; then
      while read -r file; do
        mc rm "gocache/$GOCACHE_BUCKET/$repo$branch$file"
      done <<< "$files"
    fi
  done <<< "$branches"
done <<< "$repositories"

echodate "Done :-)"
