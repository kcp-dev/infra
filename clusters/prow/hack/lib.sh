create_job_config_configmap() {
  kubectl --namespace "$PROW_NAMESPACE" create configmap job-config \
    --dry-run=client \
    --output=json > job-config.json

  for filename in prow/jobs/*/*.yaml; do
    repo="$(basename "$(dirname "$filename")")"
    basename="$(basename "$filename")"
    key="$repo-$basename"

    # yq is terrible at reading arbitrary files
    jq \
      --arg key "$key" \
      --rawfile content "$filename" \
      'setpath(["data", $key]; $content)' \
      job-config.json > job-config.json.tmp
    mv job-config.json.tmp job-config.json
  done

  yq --prettyPrint --indent 2 job-config.json > job-config.yaml
  rm job-config.json
}

sed_settings() {
  # $1 is purposefully not quoted here to allow globbing
  sed --in-place "s;__PROJECT_ID__;$PROJECT_ID;g" $1
  sed --in-place "s;__CLUSTER_ID__;$CLUSTER_ID;g" $1
  sed --in-place "s;__PROW_NAMESPACE__;$PROW_NAMESPACE;g" $1
  sed --in-place "s;__PROW_TESTPOD_NAMESPACE__;$PROW_TESTPOD_NAMESPACE;g" $1
}
