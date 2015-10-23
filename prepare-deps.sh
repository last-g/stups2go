#!/bin/sh

# Format:  url>md5>sha1>target
FILES="
https://download.go.cd/gocd-deb/go-server-15.2.0-2248.deb>84f07ddce1bc6bf095df17b2050b5fbb>63847ce16d559e9cb4d2204ead64b9bccc72fe6e>server
https://download.go.cd/gocd-deb/go-agent-15.2.0-2248.deb>2cab9a114a26543139843bb10f52a72b>2a970a5f7e83dd89813c48b261fa6ca11c2d4dcf>agent
"

for f in $FILES; do
	url=$(echo $f | cut -d'>' -f1)
	md5=$(echo $f | cut -d'>' -f2)
	sha1=$(echo $f | cut -d'>' -f3)
	dir=$(echo $f | cut -d'>' -f4)
	name=$(basename $url)
	file=$dir/$name

	if [ ! -f $file ]; then
		echo "Downloading $url to $dir/$name ..."
		wget -O $file $url || exit $?
	fi

	echo "Checking md5 sum ($md5)..."
	echo "$md5 $file" | md5sum -c || exit $?

	echo "Checking sha1 sum ($sha1)..."
	echo "$sha1 $file" | sha1sum -c || exit $?
done
