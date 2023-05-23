use_tmp_kubeconfig_context() {
  context="$1"
  echo "Switching to $context context..."

  # creating a temporary file because some kubeconfigs might be mounted
  # from Secrets and would be therefore read-only
  tmpKubeconfig=$(mktemp)
  cp "$KUBECONFIG" "$tmpKubeconfig"

  export "KUBECONFIG=$tmpKubeconfig"
  kubectl config use-context "$context"
}

deploy_helm_chart() {
  local namespace="$1"
  local release="$2"
  local chart="$3"
  local version="$4"
  local valuesFile="$5"

  helm --namespace "$namespace" upgrade \
    --install \
    --create-namespace \
    --values "$valuesFile" \
    --version $version \
    "$release" "$chart"
}
