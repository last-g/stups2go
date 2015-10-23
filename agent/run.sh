#!/bin/sh

# setup docker socket permissions for go-agent
chown :go /var/run/docker.sock

# for local development:
if [ ! -z "$GO_SERVER_LINK_PORT_8153_TCP_ADDR" ]; then
	export CONFIG_GO_SERVER=$GO_SERVER_LINK_PORT_8153_TCP_ADDR
	export CONFIG_GO_SERVER_PORT=$GO_SERVER_LINK_PORT_8153_TCP_PORT
fi

# go-agent script will switch to go user on start
exec /usr/share/go-agent/agent.sh go-agent
