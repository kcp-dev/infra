#!/usr/bin/env bash

set -euo pipefail
cd "$(dirname "$0")/.."

getTag() {
  yq '. | select(.kind=="Deployment") | .spec.template.spec.containers[0].image | split(":").[1]' -
}

currentProwVersion="$(cat manifests/prow/01-cherrypicker.yaml | getTag)"
latestProwVersion="$(curl -s https://raw.githubusercontent.com/kubernetes/test-infra/master/config/prow/cluster/deck_deployment.yaml | getTag)"

echo "Current Prow version: $currentProwVersion"
echo " Latest Prow version: $latestProwVersion"

find . -name '*.yaml' -exec sed -i "s/$currentProwVersion/$latestProwVersion/g" {} \;

curl -so manifests/prowjob-crd.yaml https://raw.githubusercontent.com/kubernetes/test-infra/master/config/prow/cluster/prowjob-crd/prowjob_customresourcedefinition.yaml

echo "Files updated, you can commit now. Good luck! :)"
