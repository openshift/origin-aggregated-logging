#!/bin/bash

set -euxo pipefail

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
        *.template.json) dest="elasticsearch/index_templates/$name" ;;
        *.index-pattern.json) dest="elasticsearch/index_patterns/$name" ;;
        *) echo Error: unknown name $name; exit 1 ;;
    esac
    curl -s -L "$url" > "$dest"
done
