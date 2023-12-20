# kcp-dev/infra/build

This directory contains files to build `ghcr.io/kcp-dev/infra/build`, the base image used for kcp's Prow jobs. It includes the following tools:

- `docker` (and `/usr/local/bin/start-docker.sh` to start it)
-  `kind` (and pre-loaded `/kindest.tar` that can be loaded into docker to have `kindest/node` available)
- `go`
- `git`, `jq` and `curl`
- `kubeconform`

## Usage

- Mount an emptyDir volume to `/docker-graph`, which is used by docker as data root. This is not strictly required but stongly suggested.
- Configure the command to be `["/bin/bash", "-c", "/usr/local/bin/start-docker.sh && $YOUR_ACTUAL_COMMAND"]`, this is required because Prow overrides the image entrypoint.

## Updates

Main component versions (Go, kind, etc) can be updated in [env](./env). Make sure to bump `BUILD_IMAGE_TAG` accordingly (the usual pattern is Go version plus a suffix that is incremented upon other version updates or addition of some tools).
