#!/usr/bin/env bash

# This script deploys Prometheus, Grafana, Loki and Alloy into the build
# cluster. Nothing here is exposed outside the cluster, use kubectl
# port-forward to reach it (see README).

set -euo pipefail

cd $(dirname $0)/../..
source ../../hack/lib.sh
source hack/settings.sh
source hack/lib.sh

if [ -n "${KUBE_CONTEXT:-}" ]; then
  use_tmp_kubeconfig_context "$KUBE_CONTEXT"
fi

echodate "Preparing Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

kubectl create namespace "$MONITORING_NAMESPACE" --dry-run=client --output yaml | kubectl apply --filename -
retry 3 kubectl apply --filename manifests/monitoring-networkpolicy.yaml

# generate the Grafana admin password once, never overwrite it
if ! kubectl --namespace "$MONITORING_NAMESPACE" get secret grafana-admin > /dev/null 2>&1; then
  echodate "Creating Grafana admin credentials..."
  kubectl --namespace "$MONITORING_NAMESPACE" create secret generic grafana-admin \
    --from-literal=admin-user=admin \
    --from-literal=admin-password="$(head -c 32 /dev/urandom | base64 | tr -d '\n')"
fi

echodate "Installing kube-prometheus-stack..."
retry 3 deploy_helm_chart "$MONITORING_NAMESPACE" kube-prometheus-stack prometheus-community/kube-prometheus-stack $KUBE_PROMETHEUS_STACK_VERSION helm-values/kube-prometheus-stack.yaml

echodate "Installing Loki..."
retry 3 deploy_helm_chart "$MONITORING_NAMESPACE" loki grafana/loki $LOKI_VERSION helm-values/loki.yaml

echodate "Installing Alloy..."
retry 3 deploy_helm_chart "$MONITORING_NAMESPACE" alloy grafana/alloy $ALLOY_VERSION helm-values/alloy.yaml

echo "Done :-)"
