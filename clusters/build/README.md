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

## Monitoring

The `monitoring` namespace runs metrics and logs for the cluster, so CI
flakes can be traced back to the node they ran on:

- [kube-prometheus-stack](./helm-values/kube-prometheus-stack.yaml):
  Prometheus (15 days), Grafana, node-exporter, kube-state-metrics. No Alertmanager.
- [Loki](./helm-values/loki.yaml): logs, 14 days.
- [Alloy](./helm-values/alloy.yaml): ships container logs and the node journal to Loki.

It is deployed by [hack/ci/deploy-monitoring.sh](./hack/ci/deploy-monitoring.sh),
which the `post-infra-deploy-build-cluster-monitoring` postsubmit runs when
the monitoring files change. To deploy by hand, run the script with a
kubeconfig for the build cluster.

Nothing is exposed outside the cluster: no Ingress or LoadBalancer, and a
[NetworkPolicy](./manifests/monitoring-networkpolicy.yaml) only allows
traffic from inside the namespace, so test pods cannot reach it. Use
`kubectl port-forward`:

```bash
# Grafana on http://localhost:3000 (user: admin)
kubectl --namespace monitoring get secret grafana-admin --output jsonpath='{.data.admin-password}' | base64 -d
kubectl --namespace monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80

# Prometheus on http://localhost:9090
kubectl --namespace monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
```

Pods carry their Prow labels (`prow.k8s.io/job`, `prow.k8s.io/refs.pull`,
`prow.k8s.io/build-id`, ...) on `kube_pod_labels` and as Loki labels
(`prow_job`, `pull`, `build_id`, `repo`). The node of a job is in its
`podinfo.json`. Some useful queries:

```promql
# CI pods that ran on a node, with their job and PR
kube_pod_info{node="10.0.112.93", namespace="default"}
  * on (namespace, pod) group_left (label_prow_k8s_io_job, label_prow_k8s_io_refs_pull)
  kube_pod_labels

# CPU used per pod on a node, compared to what it requested
sum by (pod) (rate(container_cpu_usage_seconds_total{node="10.0.112.93", container!=""}[1m]))
sum by (pod) (kube_pod_container_resource_requests{node="10.0.112.93", resource="cpu"})

# node pressure: share of time tasks were stalled on CPU, memory or IO
rate(node_pressure_cpu_waiting_seconds_total[1m])
rate(node_pressure_memory_stalled_seconds_total[1m])
rate(node_pressure_io_stalled_seconds_total[1m])
```

```logql
{prow_job="pull-kcp-test-e2e-sharded", pull="4494"}
{job="node/journal", node="10.0.112.93"} |~ "(?i)oom|hung task|blocked for more than"
```

## Goproxy

[Athens](https://github.com/gomods/athens) is installed, but optional.
Configure a Prowjob with the `preset-goproxy: "true"` label to opt-in to
the proxy (the preset sets `$GOPROXY`).
