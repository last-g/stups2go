#!/bin/sh

cd $(basename $0)
source ./build-versions.sh

for toolchain in $TOOLCHAINS; do
	file=$(echo $toolchain | sed 's/:.*//g')
	docker build -t registry.opensource.zalan.do/stups/toolchain-${toolchain} -f ${file}.dockerfile .
done
