#!/usr/bin/env bash

## This script should be called by all containers that
## want to use docker-in-docker. This ensures a consistent
## setup instead of homegrown custom hacks in each
## repository.
## It is safe to call this multiple times, only the first
## invocation will start the daemon.

set -euo pipefail

retry() {
  # Works only with bash but doesn't fail on other shells
  set +e
  actual_retry $@
  rc=$?
  set -e
  return $rc
}

# We use an extra wrapping to write junit and have a timer
actual_retry() {
  retries=$1
  shift

  count=0
  delay=1
  until "$@"; do
    rc=$?
    count=$((count + 1))
    if [ $count -lt "$retries" ]; then
      echo "Retry $count/$retries exited $rc, retrying in $delay seconds..." > /dev/stderr
      sleep $delay
    else
      echo "Retry $count/$retries exited $rc, no more retries left." > /dev/stderr
      return $rc
    fi
    delay=$((delay + 1))
  done
  return 0
}

echodate() {
  # do not use -Is to keep this compatible with macOS
  echo "[$(date +%Y-%m-%dT%H:%M:%S%:z)]" "$@"
}

# does Docker already run?
if docker stats --no-stream > /dev/null 2>&1; then
  exit 0
fi

echodate "Starting Docker"

# This is needed so Docker-In-Docker still works when the peer doesn't allow ICMP packages and hence path mtu discovery cant work
# Most notably, pmtud doesn't work with the hoster of the Alpine package mirror, fastly, causing dind builds of alpine to hang
# forever. Upstream issue: See https://github.com/gliderlabs/docker-alpine/issues/307#issuecomment-427246497
echodate "Configuring iptables"
iptables -t mangle -A POSTROUTING -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

# Configure a registry mirror. This will help only the `docker build` commands during
# regular Prow job, but will not affect any kind clusters that are started from within
# Prow jobs.
registryMirror="${DOCKER_REGISTRY_MIRROR:-}"
if [ -n "$registryMirror" ]; then
  echodate "Configuring registry mirror"
  jq --arg mirror "$registryMirror" '."registry-mirrors" = [$mirror]' /etc/docker/daemon.json > /etc/docker/daemon.new.json
  mv /etc/docker/daemon.new.json /etc/docker/daemon.json
fi

mtu=${DOCKER_MTU:-0}
if [[ $mtu -gt 0 ]]; then
  echodate "Configuring MTU"
  jq --argjson mtu $mtu '.mtu = $mtu' /etc/docker/daemon.json > /etc/docker/daemon.new.json
  mv /etc/docker/daemon.new.json /etc/docker/daemon.json
fi

# start Docker daemon
service docker start

# wait for Docker to start
retry 5 docker stats --no-stream
echodate "Docker became ready"
