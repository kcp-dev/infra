# Build Cluster

This directory contains the manifests for managing the build cluster. This
is the cluster where most of the Prow jobs are executed.

## Nodes

There are 2 MachineDeployments in this cluster:

* `workers` are the regular worker machines. This MachineDeployment is
  automatically scaled by the cluster-autoscaler to match demand.
* `stable` are a set of stable nodes that run cluster-wide services
  like the Go-Proxy, the registry mirror etc. -- things that should not
  randomly go away when worker nodes are decommissioned.

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
