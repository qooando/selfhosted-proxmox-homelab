#!/bin/bash

KEEP=${keep}
if ! $KEEP; then
  skopeo delete --tls-verify=false docker://${tag} || true
fi
