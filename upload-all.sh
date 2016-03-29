#!/bin/sh

set -x
set -e

cd $(dirname $0)

[ -z "$VERSION" ] && VERSION=0-SNAPSHOT

# upload Docker images
docker push registry-write.opensource.zalan.do/stups/go-server:$VERSION
docker push registry-write.opensource.zalan.do/stups/go-agent:$VERSION

