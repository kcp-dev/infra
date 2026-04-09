#!/usr/bin/env sh

# takes the resources.go from the kcp-operator and returns the ImageTag value

tag="$(grep -E 'ImageTag\s*=' | sed -E "s#\s*ImageTag\s*=\s*\"(.+?)\"#\1#")"

if ! [[ $tag =~ ^v ]]; then
  tag="$(echo "$tag" | cut -c1-8)…"
fi

echo -n "$tag"
