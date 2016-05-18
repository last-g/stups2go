#!/bin/sh

COMMAND=$*
if [ -z "$COMMAND" ]; then
	echo "Command not given!" >&2
	exit 1
fi

if [ -z "$USER_ID" ]; then
	$COMMAND
	exit $?
fi

useradd -u $USER_ID -d $HOME -M -s /bin/bash worker
su worker --preserve-environment -c "$COMMAND"
