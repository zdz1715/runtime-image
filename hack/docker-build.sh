#!/usr/bin/env bash

set -o errexit
set -o pipefail

# This script holds docker related functions.

root="."

registry="runtime"
version="latest"
params=""
if [ -n "$REGISTRY" ]; then
  registry="$REGISTRY"
fi

if [ -n "$VERSION" ]; then
  version="$VERSION"
fi

if [ -n "$ARGS" ]; then
  params="$ARGS "
fi


function build_images() {
  local target="$1"
  echo "docker build --progress=plain $params-t $registry:$version -f $root/images/$target/Dockerfile $root"
  sh -c "docker build --progress=plain $params-t $registry:$version -f $root/images/$target/Dockerfile $root"
}

build_images "$@"
