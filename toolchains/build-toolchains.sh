#!/bin/sh

cd $(dirname $0)
. ./build-versions.sh

for toolchain in $TOOLCHAINS; do
	file=$(echo $toolchain | sed 's/:.*//g')
	docker build -t registry.opensource.zalan.do/stups/toolchain-${toolchain} -f ${file}.dockerfile .
done
