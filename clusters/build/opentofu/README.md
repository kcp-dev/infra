# build cluster opentofu

OpenTofu modules for the kcp build cluster on OCI. Each subdirectory is a standalone working directory with its own state file in the shared `kcp-opentofu-state` bucket.

- [cluster](./cluster) — the `oci-prow-worker` OKE cluster, networking, and addons. State key: `ci-prow-worker/tf.tfstate`.
- [perf-testing-infra](./perf-testing-infra) — public-read Object Storage bucket plus a dedicated OCI user/key for uploading perf-test results from CI. State key: `perf-testing-infra/tf.tfstate`.

Both modules share the same OCI auth setup; see [cluster/README.md](./cluster/README.md) for the env var details. You can either keep one `.env` at this level and `source ../.env` from each subdir, or keep separate ones.
