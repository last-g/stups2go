#!/bin/sh

set -x
set -e

cd $(dirname $0)

# download dependencies
./prepare-deps.sh

# build custom go extensions
mvn -f server/authentication-plugin/pom.xml clean package

[ -z "$VERSION" ] && VERSION=0-SNAPSHOT

# build Docker images
docker build -f server/Dockerfile -t registry.opensource.zalan.do/stups/go-server:$VERSION server
docker build -f agent/Dockerfile -t registry.opensource.zalan.do/stups/go-agent:$VERSION agent

# build toolchains
toolchains/build-toolchains.sh
