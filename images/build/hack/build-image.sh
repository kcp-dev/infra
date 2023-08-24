#!/usr/bin/env bash

# Copyright 2023 The KCP Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euo pipefail

# in CI, make use of the registry mirror to avoid getting rate limited
if [ -n "${DOCKER_REGISTRY_MIRROR_ADDR:-}" ]; then
  # remove "http://" or "https://" prefix
  mirror="$(echo "$DOCKER_REGISTRY_MIRROR_ADDR" | awk -F// '{print $NF}')"

  echo "Configuring registry mirror for docker.io ..."

  cat <<EOF > /etc/containers/registries.conf.d/mirror.conf
[[registry]]
prefix = "docker.io"
insecure = true
location = "$mirror"
EOF
fi

repository=ghcr.io/kcp-dev/infra/build
architectures="amd64"

cd ./images/build

# read configuration file for build image
source ./env

# download kind image
echo "Downloading kindest image to embed into image ..."
buildah pull docker.io/${KINDEST_NODE_IMAGE}
buildah push --format docker docker.io/${KINDEST_NODE_IMAGE} docker-archive:kindest.tar:${KINDEST_NODE_IMAGE}

image="$repository:${BUILD_IMAGE_TAG}"
echo "Building container image $image ..."

# build image for all architectures
for arch in $architectures; do
  fullTag="$image-$arch"

  echo "Building $image-$arch ..."
  buildah build-using-dockerfile \
    --file Dockerfile \
    --tag "$fullTag" \
    --arch "$arch" \
    --override-arch "$arch" \
    --build-arg "GO_VERSION=${GO_IMAGE_VERSION}" \
    --build-arg "K8S_VERSION=${K8S_VERSION}" \
    --build-arg "KIND_VERSION=${KIND_VERSION}" \
    --format=docker \
    .
done

echo "Creating manifest $image ..."
buildah manifest create "$image"
for arch in $architectures; do
  buildah manifest add "$image" "$image-$arch"
done

# push manifest, except in presubmits
if [ -z "${DRY_RUN:-}" ]; then
  echo "Logging into GHCR ..."
  buildah login --username "$KCP_GHCR_USERNAME" --password "$KCP_GHCR_PASSWORD" ghcr.io

  echo "Pushing manifest and images ..."
  buildah manifest push --all "$image" "docker://$image"
else
  echo "Not pushing images because \$DRY_RUN is set."
fi

echo "Done."
