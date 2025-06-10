# Build Cluster

This directory contains the manifests for managing the build cluster. This
is the cluster where most of the kcp Prow jobs are executed.

The cluster has been deployed from the IaC files in [opentofu](./opentofu/) but some manual modifications were necessary.
Check the linked README for details.

## Nodes

This cluster has been configured with the [cluster-autoscaler addon](./opentofu/addons.tf) to scale up to 5 nodes.

Each node is configured with 16GB RAM / 8 vCPUs (ARM-based).

<!--
## Docker Registry Mirror

The cluster is configured to provision each node with a container registry
mirror, which runs inside the cluster itself (all nodes proxy requests to
docker.io through this mirror). This mirror is meant to prevent rate limits
from upstream registries.

In case a job runs docker-in-docker or similar setups, the inner container
engine can be pointed to `$DOCKER_REGISTRY_MIRROR_ADDR` (has a value like
`http://registry-mirror.registry.svc.cluster.local:5001`) to make it use
the proper mirror.
-->

## Goproxy

[Athens](https://github.com/gomods/athens) is installed, but optional.
Configure a Prowjob with the `preset-goproxy: "true"` label to opt-in to
the proxy (the preset sets `$GOPROXY`).
