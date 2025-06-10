sed_settings() {
  # $1 is purposefully not quoted here to allow globbing
  sed --in-place "s;__PROW_TESTPOD_NAMESPACE__;$PROW_TESTPOD_NAMESPACE;g" $1
}

echodate() {
  echo "[$(date +%Y-%m-%dT%H:%M:%S%:z)]" "$@"
}
