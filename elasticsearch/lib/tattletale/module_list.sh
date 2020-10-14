#!/bin/bash
# this can be run with podman to generate the manifest
# podman run --volume /tmp:/tmp -it openshift/origin-logging-elasticsearch6 sh module_list.sh

MODULE_FILE=${MODULE_FILE:-/tmp/rh-manifest.txt}

unzip -q tattletale-1.2.0.Beta2.zip
cd tattletale-1.2.0.Beta2

echo -- building "$MODULE_FILE"

java -Xmx512m -jar tattletale.jar /usr/share/elasticsearch/ . 2>/dev/null

cat index.html | sed -n -e '/Archives/,/<\/ul>/p' | grep '<li>' | sed -e 's/^.*\.html\">//' -e 's/<\/a>.*$//' > ${MODULE_FILE}

echo -- completed!