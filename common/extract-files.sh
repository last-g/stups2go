#!/bin/sh

echo "Extracing files from STUPS_FILES..."

cd $HOME
for file in $(echo $STUPS_FILES | sed 's/,/ /g'); do
    fname=$(echo $file | cut -d ':' -f1)
    fcontent=$(echo $file | cut -d ':' -f2)

    mkdir -p $(dirname $fname)
    echo $fcontent | base64 -d > $fname

    chmod 0400 $fname

    ls -l $fname
done

echo "File extraction finished."
