#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}" )/../lib/init.sh"

docker_uses_journal() {
    # note the unintuitive logic - in this case, a 0 return means true, and a 1
    # return means false
    # need to be able to handle cases like
    # OPTIONS='--log-driver=json-file ....' # or use --log-driver=journald
    # if "log-driver" is set in /etc/docker/daemon.json, assume that it is
    # authoritative
    # otherwise, look for /etc/sysconfig/docker
    if type -p docker > /dev/null && sudo docker info | grep -q 'Logging Driver: journald' ; then
        return 0
    elif grep -q '^[^#].*"log-driver":' /etc/docker/daemon.json 2> /dev/null ; then
        if grep -q '^[^#].*"log-driver":.*journald' /etc/docker/daemon.json 2> /dev/null ; then
            return 0
        fi
    elif grep -q "^OPTIONS='[^']*--log-driver=journald" /etc/sysconfig/docker 2> /dev/null ; then
        return 0
    fi
    return 1
}

if [ -z "${USE_JOURNAL:-}" ] ; then
    if docker_uses_journal ; then
        USE_JOURNAL=true
    else
        USE_JOURNAL=false
    fi
fi

USE_JOURNAL="${USE_JOURNAL}"    \
OAL_ELASTICSEARCH_COMPONENT="es" \
OAL_KIBANA_COMPONENT="kibana"   \
OAL_ELASTICSEARCH_SERVICE="logging-es" \
"${OS_O_A_L_DIR}/test/cluster/functionality.sh"

if [ "$1" = "true" ]; then
  # There is an ops cluster set up, so we
  # need to verify it's functionality as well.
  USE_JOURNAL="${USE_JOURNAL}"        \
  OAL_ELASTICSEARCH_COMPONENT="es-ops" \
  OAL_KIBANA_COMPONENT="kibana-ops"   \
  OAL_ELASTICSEARCH_SERVICE="logging-es-ops" \
  "${OS_O_A_L_DIR}/test/cluster/functionality.sh"
fi
