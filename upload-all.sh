#!/bin/sh

set -x
set -e

cd $(dirname $0)

# upload Docker images
docker push registry.opensource.zalan.do/stups/noop:0-SNAPSHOT
docker push registry.opensource.zalan.do/stups/go-server:0-SNAPSHOT
docker push registry.opensource.zalan.do/stups/go-agent:0-SNAPSHOT

