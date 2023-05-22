# Prow Cluster

This directory contains the manifests for managing the Prow cluster that
powers the CI/CD system for [kcp](https://github.com/kcp-dev/kcp). This
cluster only contains Prow itself, the build jobs are executed in another
cluster (`build`).

With few exceptions, no Prow jobs should be run in this cluster.

## Docker Registry Mirror

The cluster is configured to provision each node with a container registry
mirror, which runs inside the cluster itself (all nodes proxy requests to
docker.io through this mirror). This mirror is meant to prevent rate limits
from upstream registries.

In case a job runs docker-in-docker or similar setups, the inner container
engine can be pointed to `$DOCKER_REGISTRY_MIRROR_ADDR` (has a value like
`http://registry-mirror.registry.svc.cluster.local:5001`) to make it use
the proper mirror.

## Goproxy

[Athens](https://github.com/gomods/athens) is installed, but optional.
Configure a Prowjob with the `preset-goproxy: "true"` label to opt-in to
the proxy (the preset sets `$GOPROXY`).
