#!/usr/bin/env bash

# This script creates secrets in the cluster based on values
# from Vault. These secrets are used by Prow itself (including
# the sidecars in test pods).

set -euo pipefail

cd $(dirname $0)/..
source hack/settings.sh
source hack/lib.sh

data="$(vault kv get -format=json "$VAULT_PROW_SECRET")"

##############################################
# configure Prow

sed_settings prow/config.yaml
sed_settings prow/plugins.yaml

kubectl --namespace "$PROW_NAMESPACE" create configmap config \
  --from-file=config.yaml=prow/config.yaml \
  --dry-run=client \
  --output=yaml \
  | kubectl apply -f -

# ... and its plugins
kubectl --namespace "$PROW_NAMESPACE" create configmap plugins \
  --from-file=plugins.yaml=prow/plugins.yaml \
  --dry-run=client \
  --output=yaml \
  | kubectl apply -f -

# ... and its global jobs
create_job_config_configmap
kubectl replace -f job-config.yaml

# ... and the Github webhook secret token
kubectl --namespace "$PROW_NAMESPACE" create secret generic github-hmac-token \
  --from-literal="token=$(echo "$data" | jq -r '.data.data."github-hmac-token"')" \
  --dry-run=client \
  --output=yaml \
  | kubectl apply -f -

# ... and the token for Slack notifications
kubectl --namespace "$PROW_NAMESPACE" create secret generic slack-token \
  --from-literal="token=$(echo "$data" | jq -r '.data.data."slack-token"')" \
  --dry-run=client \
  --output=yaml \
  | kubectl apply -f -

# ... and the key for cookie encryption
# Prow expects a file with base64-encoded data in it, so that the cookie
# key can be binary; we keep the raw key in vault and perform this base64
# wrapping here, as it's a Prow implementation detail.
kubectl --namespace "$PROW_NAMESPACE" create secret generic cookie \
  --from-literal="secret=$(echo "$data" | jq -r '.data.data."cookie-secret" | @base64')" \
  --dry-run=client \
  --output=yaml \
  | kubectl apply -f -

# ... and the token for Prow to interact with GitHub
# (there are 2, one with write permissions and one with read-only permissions)
kubectl --namespace "$PROW_NAMESPACE" create secret generic github-token \
  --from-literal="token=$(echo "$data" | jq -r '.data.data."github-token"')" \
  --dry-run=client \
  --output=yaml \
  | kubectl apply -f -

kubectl --namespace "$PROW_NAMESPACE" create secret generic github-ro-token \
  --from-literal="token=$(echo "$data" | jq -r '.data.data."github-ro-token"')" \
  --dry-run=client \
  --output=yaml \
  | kubectl apply -f -

# create two S3 credentials Secrets, both in the Prow namespace and in the
# test pod namespace (for the sidecars)

for kind in internal public; do
  echo "$data" | jq "{
    region: \"eu-west-1\",
    s3_force_path_style: true,
    access_key: .data.data.\"s3-$kind-access-key\",
    secret_key: .data.data.\"s3-$kind-secret-key\",
  }" > s3-credentials.json

  for ns in $PROW_NAMESPACE $PROW_TESTPOD_NAMESPACE; do
    kubectl --namespace "$ns" create secret generic s3-credentials-$kind \
      --from-file="credentials.json=s3-credentials.json" \
      --dry-run=client \
      --output=yaml \
      | kubectl apply -f -
  done

  rm s3-credentials.json
done

# configure how oauth2-proxies authenticate against GitHub
kubectl --namespace "$PROW_NAMESPACE" create secret generic deck-oauth-app \
  --from-literal="clientID=$(echo "$data" | jq -r '.data.data."deck-oauth-client-id"')" \
  --from-literal="clientSecret=$(echo "$data" | jq -r '.data.data."deck-oauth-client-secret"')" \
  --from-literal="cookieSecret=$(echo "$data" | jq -r '.data.data."deck-oauth-cookie-secret"')" \
  --dry-run=client \
  --output=yaml \
  | kubectl apply -f -

kubectl --namespace "$PROW_NAMESPACE" create secret generic gcsweb-oauth-app \
  --from-literal="clientID=$(echo "$data" | jq -r '.data.data."gcsweb-oauth-client-id"')" \
  --from-literal="clientSecret=$(echo "$data" | jq -r '.data.data."gcsweb-oauth-client-secret"')" \
  --from-literal="cookieSecret=$(echo "$data" | jq -r '.data.data."gcsweb-oauth-cookie-secret"')" \
  --dry-run=client \
  --output=yaml \
  | kubectl apply -f -

##############################################
# create a kubeconfig for Prow (now for only a single
# cluster in is there, so we could also use the in-cluster
# config, but this prepares us for when we add more clusters)

# get the kubeconfig that is meant for the kcp-prow; so far
# we have been using the one meant for Kubermatic's Prow.
KKP_TOKEN="$(echo "$data" | jq -r '.data.data."kubermatic-token"')"
curl \
  --header "Authorization: Bearer $KKP_TOKEN" \
  https://captain.k8c.io/api/v1/projects/$PROJECT_ID/dc/captain/clusters/$CLUSTER_ID/kubeconfig | \
  yq -o=json > prow.kubeconfig

rename_kube_context prow.kubeconfig default
yq --indent 2 --prettyPrint prow.kubeconfig > prow.kubeconfig.yaml

kubectl create secret generic kubeconfig \
  --namespace "$PROW_NAMESPACE" \
  --dry-run=client \
  --output=yaml \
  --from-file "kubeconfig=prow.kubeconfig.yaml" \
  | kubectl apply -f -
