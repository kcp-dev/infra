#!/usr/bin/env sh

# takes a Dockerfile and returns the version of either the first image or the first $IMAGE image

if [ -z "$IMAGE" ]; then
  cat | grep "FROM " | head -n1 | sed -E 's/ (as|AS) [a-z-]+$//' | cut -d':' -f 2
else
  cat | grep "FROM " | sed -E 's/ (as|AS) [a-z-]+$//' | grep "$IMAGE:" | head -n1 | cut -d':' -f 2
fi
