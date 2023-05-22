sed_settings() {
  # $1 is purposefully not quoted here to allow globbing
  sed --in-place "s;__PROJECT_ID__;$PROJECT_ID;g" $1
  sed --in-place "s;__CLUSTER_ID__;$CLUSTER_ID;g" $1
}
