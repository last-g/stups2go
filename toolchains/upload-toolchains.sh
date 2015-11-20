#!/bin/sh

source ./build-versions.sh

FAILED=
for toolchain in $TOOLCHAINS; do
	docker push registry.opensource.zalan.do/stups/toolchain-${toolchain}
	[ $? -ne 0 ] && FAILED="$FAILED $toolchain"
done

[ ! -z "$FAILED" ] && echo "The following images could not be uploaded: $FAILED"
