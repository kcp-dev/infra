# Prow Cluster

This directory contains the manifests for managing the Prow cluster that
powers the CI/CD system for [kcp](https://github.com/kcp-dev/kcp). This
cluster only contains Prow itself, the build jobs are executed in another
cluster (`build`).

## Docker Registry Mirror

The cluster runs a simple registry pull-through mirror, with haproxy running
as a DaemonSet on all machines, routing the traffic to the registry mirror.
See the `manifests/registry-mirror.yaml` for more information.

## Secrets

The `hack/create-secrets.sh` script copies a select few secrets from Vault
into the cluster. This is done for frequently used secrets and when a Vault
CLI is not available inside a Prowjob.

This script is only usable by Vault admins, as it requires access to some
holy values, like the triage-bot's token. If you are an admin, you can run
it like so:

```bash
$ export VAULT_ADDR=https://vault.kubermatic.com
$ vault login --method=oidc --path=loodse
$ ./hack/create-secrets.sh
```
