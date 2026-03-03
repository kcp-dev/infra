# Container Images

This directory contains container image related scripts and manifests.

## Build Image

In [`build`](build/) are all the manifests for the common `ghcr.io/kcp-dev/infra/build`, used for many kcp Prowjobs. This image contains a whole bunch of commonly used tools that are too expensive to re-download for every single job.

## Docker Hub Mirrors

To make the CI cluster's registry mirror independent of Docker Hub, we are mirroring the required components (registry and HAProxy) into our GHCR at `kcp-dev/infra`:

* https://github.com/kcp-dev/infra/pkgs/container/infra%2Fregistry
* https://github.com/kcp-dev/infra/pkgs/container/infra%2Fhaproxy

There is currently no automation in place to update these mirrors. Someone just pulled them once, manually pushed them to GHCR and that's it.
