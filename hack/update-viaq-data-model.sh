#!/bin/bash

# Script downloads elasticsearch templates for specified ES version only
# and removes the ES version pattern from the file name before storing it.
#
# ES version must be supplied as an argument.
#
# Example:
# $ update-viaq-data-model.sh 5.5.2

set -euxo pipefail

if [ $# -eq 0 ]
  then
    echo "No supported ES version supplied as an argument. (Eg. 2.4.4 or 5.5.2)"
fi
ES_VERSION=$1
echo "Downloading resources for ES version '${ES_VERSION}'"

RELEASE_URL=${RELEASE_URL:-https://api.github.com/repos/ViaQ/elasticsearch-templates/releases/latest}

asset_urls=$( curl -s $RELEASE_URL | \
                  python -c 'import sys,json
for asset in json.load(sys.stdin)["assets"]:
  print asset["name"], asset["browser_download_url"]
' )

set -- $asset_urls
while [ "${1:-}" ] ; do
    name="$1"; shift
    url="$1"; shift
    case "$name" in
        *.asciidoc) dest="docs/$name" ;;
        *.${ES_VERSION}.template.json) dest="elasticsearch/index_templates/$name"; dest=${dest//.${ES_VERSION}/} ;;
        *.${ES_VERSION}.index-pattern.json) dest="elasticsearch/index_patterns/$name"; dest=${dest//.${ES_VERSION}/} ;;
        *) echo Skipping file $name; continue ;;
    esac
    curl -s -L "$url" > "$dest"
done
