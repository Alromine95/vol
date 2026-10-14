#!/bin/bash

set -eE
trap 'echo " FAILED at ${BASH_SOURCE[0]}:${LINENO} -> $BASH_COMMAND"; exit 1' ERR

#Removing old manifests
rm -rf .repo/local_manifests
echo "  Local manifests deleted  "

