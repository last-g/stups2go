#!/bin/sh

# Format:  url>md5>sha1>target
FILES="
https://download.go.cd/binaries/16.2.1-3027/deb/go-server-16.2.1-3027.deb>c80edfccbd42a37ffbe554fcac4c21c9>dd3381a0e73c4aba34e328674e97ace50958c208>server
https://download.go.cd/binaries/16.2.1-3027/deb/go-agent-16.2.1-3027.deb>1e9c21f12e1fd41f36e157f86b113e29>d72f8e314499e69dfd56741a866f08cfa695def2>agent
https://github.com/gocd-contrib/gocd-oauth-login/releases/download/v1.2/github-oauth-login-1.2.jar>31ad9ad1fe08452f73c56a44b035ee91>1bea6bb7da660544c1a4686e7ecf5d7c556e5fcd>server
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

# setup hardlinks for common files
echo "Setting up common hardlinks..."
for file in extract-files.sh; do
    [ ! -f server/$file ] && ln common/$file server/$file
    [ ! -f agent/$file ] && ln common/$file agent/$file
done

exit 0
