#!/usr/bin/env bash

set -euo pipefail
cd "$(dirname "$0")/.."

getTag() {
  yq '. | select(.kind=="Deployment") | .spec.template.spec.containers[0].image | split(":").[1]' -
}

latestTag() {
  local host="$1"
  local repository="$2"

  # get all tags, filter to keep only version tags, sort reverse as version number, take the top one (latest)
  curl --silent --fail https://$host/v2/$repository/tags/list | jq -r '.tags[]' | grep '^v20' | sort -rV | head -n1
}

currentProwVersion="$(cat manifests/prow/01-cherrypicker.yaml | getTag)"
latestProwVersion="$(latestTag us-docker.pkg.dev k8s-infra-prow/images/prow-controller-manager)"

echo "Current Prow version: $currentProwVersion"
echo " Latest Prow version: $latestProwVersion"

find ../../ -name '*.yaml' -exec sed -i "s/$currentProwVersion/$latestProwVersion/g" {} \;

curl -so manifests/prowjob-crd.yaml https://raw.githubusercontent.com/kubernetes-sigs/prow/main/config/prow/cluster/prowjob-crd/prowjob_customresourcedefinition.yaml

# remove all descriptions to trim down the CRD, otherwise it exceeds ectd's object size limit
yq -i 'del(.. | (select(has("description")).description))' manifests/prowjob-crd.yaml

#############################
# update related k8s test-infra images

for progname in commenter label_sync gcsweb; do
  latestVersion="$(latestTag gcr.io k8s-staging-test-infra/$progname)"

  echo "Latest $progname version: $latestVersion"

  # search the _entire_ repository to also catch the .prow.yaml
  find .. -name '*.yaml' -exec sed -i -E "s#k8s-staging-test-infra/$progname:[0-9a-z-]+#k8s-staging-test-infra/$progname:$latestVersion#g" {} \;
done

echo "Files updated, you can commit now. Good luck! :)"
