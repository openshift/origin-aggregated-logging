#!/bin/bash

set -ex
set -o nounset
set -o pipefail

source "${HOME}/prep-install.${RELEASE_STREAM}"

# https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash

# compare_versions takes two seminial versions and compares them
# return -1, 0, 1 depending of arg1 is less than, equal to,
#        or greater than arg2
compare_versions() {
    if [[ $1 == $2 ]]
    then
        echo 0
        return 0
    fi  
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do  
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do  
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            echo 1
            return 0
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            echo -1
            return 0
        fi
    done
    echo 0
    return 0
}

# patch kibana 5.6.x
# ref: https://gist.github.com/FireBurn/2ecaaff4c40a6dd9bb865f732a9754a7
min_version=$(compare_versions "$KIBANA_VER" "5.6.13")
max_version=$(compare_versions "$KIBANA_VER" "6.0")
if [ "$min_version" -ge "0" ] && [ "$max_version" -eq "-1" ]  ; then
    echo "Patching Kibana to address bz 1679159"
    cp -r $HOME/patches/kibana5.6.13/elasticsearch-js-679/src $KIBANA_HOME/node_modules/elasticsearch/
fi

ORIGIN_KIBANA_PLUGIN=$(ls -t1 ${HOME}/origin-kibana-v${KIBANA_VER}*.zip | head -1)
${KIBANA_HOME}/bin/kibana-plugin install file://${ORIGIN_KIBANA_PLUGIN}

chmod -R og+w "${HOME}"
chmod -R og+rw "${KIBANA_HOME}"
mkdir -m og+w -p /var/lib/kibana
chmod -R og+w "${KIBANA_CONF_DIR}"

