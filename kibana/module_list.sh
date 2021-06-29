#!/bin/bash
# this can be run with podman to generate the manifest
# podman run --volume /tmp:/tmp -it openshift/origin-logging-kibana6 sh module_list.sh


MODULE_FILE=${MODULE_FILE:-/tmp/rh-manifest.txt}
WORKING_FILE="$(mktemp /tmp/moduleXXXXXXXX)"

function npm_version() {
    # quick and dirty fix to specify python3 here -- FIXME: fix the docker build so we can just use "python"
    npm ls --json 2>/dev/null | python3 -c 'import sys,json; data = json.load(sys.stdin); print("{0} == {1}".format(data["name"], data["version"]))'
}

echo -- building "$MODULE_FILE"

for dir in $(ls -d node_modules/* node_modules/*/node_modules/* plugins/*/node_modules/*); do
  if [ -f ${dir}/package.json ]; then
    pushd ${dir} > /dev/null
    npm_version >> $WORKING_FILE
    popd > /dev/null
  fi
done

ls -l $WORKING_FILE

sort $WORKING_FILE | uniq > "$MODULE_FILE"
rm "$WORKING_FILE"

echo -- completed!