#!/bin/bash

IMAGE=${tag}
KEEP=${keep}

skopeo delete --tls-verify=false docker://$IMAGE || true

if ! buildah bud --layers -f ./Dockerfile -t "$IMAGE" --format "oci"; then
  exit 1
fi

if ! buildah push --tls-verify=false "$IMAGE"; then
  exit 2
fi

if ! $KEEP; then
  buildah rmi "$IMAGE" || true
fi