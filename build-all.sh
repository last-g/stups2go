#!/bin/sh

set -x
set -e

cd $(dirname $0)

# download dependencies
./prepare-deps.sh

# build custom go extensions
mvn -f server/authentication-plugin/pom.xml clean package

# build Docker images
docker build --no-cache -f noop/Dockerfile -t registry.opensource.zalan.do/stups/noop:0-SNAPSHOT noop
docker build --no-cache -f server/Dockerfile -t registry.opensource.zalan.do/stups/go-server:0-SNAPSHOT server
docker build --no-cache -f agent/Dockerfile -t registry.opensource.zalan.do/stups/go-agent:0-SNAPSHOT agent
