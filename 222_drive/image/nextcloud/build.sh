#!/bin/bash

IMAGE=localhost/nextcloud:local
buildah bud --layers -f ./Dockerfile -t "$IMAGE" --format "oci"