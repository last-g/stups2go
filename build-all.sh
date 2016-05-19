#!/bin/sh

set -x
set -e

cd $(dirname $0)

# download dependencies
./prepare-deps.sh

[ -z "$VERSION" ] && VERSION=0-SNAPSHOT

# build Docker images
scm-source -f server/scm-source.json
docker build -f server/Dockerfile -t registry-write.opensource.zalan.do/stups/go-server:$VERSION server
scm-source -f agent/scm-source.json
docker build -f agent/Dockerfile -t registry-write.opensource.zalan.do/stups/go-agent:$VERSION agent

# build toolchains
toolchains/build-toolchains.sh
