#!/bin/sh

set +x
set +e

cd $(dirname $0)

# download dependencies
./prepare-deps.sh

# build custom go extensions
mvn -f server/authentication-plugin/pom.xml clean package

# build Docker images
docker build -f noop/Dockerfile -t registry.opensource.zalan.do/stups/noop:0-SNAPSHOT noop
docker build -f server/Dockerfile -t registry.opensource.zalan.do/stups/go-server:0-SNAPSHOT server
docker build -f agent/Dockerfile -t registry.opensource.zalan.do/stups/go-agent:0-SNAPSHOT agent
