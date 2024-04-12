#!/bin/sh

set -e

# This script runs in the gcr.io/k8s-prow/commenter image
# and takes care of marking Github issues without activity
# progressively as stale, rotten and eventually closes them.

if [ -z "${GITHUB_TOKEN_FILE:-}" ]; then
  echo "No GITHUB_TOKEN_FILE variable set."
  exit 1
fi

# this will be added to every search query
baseQuery='repo:kcp-dev/kcp
repo:kcp-dev/helm-charts
repo:kcp-dev/infra
repo:kcp-dev/controller-runtime
repo:kcp-dev/controller-runtime-example
repo:kcp-dev/logicalcluster
repo:kcp-dev/kcp.io
-label:kind/documentation
-label:kind/feature
-label:kind/cleanup
-label:epic'

case "$KIND" in
  stale)
    updated=2160h
    query='-label:lifecycle/frozen -label:lifecycle/stale -label:lifecycle/rotten'
    comment='Issues go stale after 90d of inactivity.
After a furter 30 days, they will turn rotten.
Mark the issue as fresh with `/remove-lifecycle stale`.

If this issue is safe to close now please do so with `/close`.

/lifecycle stale'
    ;;

  rotten)
    updated=720h
    query='-label:lifecycle/frozen label:lifecycle/stale -label:lifecycle/rotten'
  comment='Stale issues rot after 30d of inactivity.
Mark the issue as fresh with `/remove-lifecycle rotten`.
Rotten issues close after an additional 30d of inactivity.

If this issue is safe to close now please do so with `/close`.

/lifecycle rotten'
    ;;

  close)
    updated=720h
    query='-label:lifecycle/frozen label:lifecycle/rotten'
  comment='Rotten issues close after 30d of inactivity.
Reopen the issue with `/reopen`.
Mark the issue as fresh with `/remove-lifecycle rotten`.

/close'
    ;;

*)
    echo "Invalid \$KIND given: $KIND"
    exit 1
    ;;
esac

# safety first, set $CONFIRM to any value to actually perform changes
confirmFlag=''
if [ -n "${CONFIRM:-}" ]; then
  confirmFlag='-confirm'
fi

commenter $confirmFlag \
  -query="$baseQuery $query" \
  -updated=$updated \
  -token="$GITHUB_TOKEN_FILE" \
  -comment="$comment" \
  -template \
  -ceiling=10
