#!/bin/bash

if [[ $VERBOSE ]]; then
  set -ex
else
  set -e
  VERBOSE=
fi
set -o nounset
set -o pipefail

if ! type get_running_pod > /dev/null 2>&1 ; then
    . ${OS_O_A_L_DIR:-../..}/deployer/scripts/util.sh
fi

if [ "$USE_MUX_CLIENT" = "true" ] ; then
    echo "Skipping -- This test is exclusive to USE_MUX_CLIENT != true."
    exit 0
fi

if [[ $# -ne 1 || "$1" = "false" ]]; then
  # assuming not using OPS cluster
  CLUSTER="false"
  ops=
else
  CLUSTER="$1"
  ops="-ops"
fi

# not used for now, but in case
INDEX_PREFIX=
PROJ_PREFIX=project.

ARTIFACT_DIR=${ARTIFACT_DIR:-${TMPDIR:-/tmp}/origin-aggregated-logging}
if [ ! -d $ARTIFACT_DIR ] ; then
    mkdir -p $ARTIFACT_DIR
fi

get_test_user_token

write_and_verify_logs() {
    rc=0
    if ! wait_for_fluentd_to_catch_up "" "" $1 ; then
        rc=1
    fi

    if [ $rc -ne 0 ]; then
        echo test-es-copy.sh: returning $rc ...
    fi
    return $rc
}

undeploy_fluentd() {
    fpod=`get_running_pod fluentd`

    # undeploy fluentd
    oc label node --all logging-infra-fluentd-

    wait_for_pod_ACTION stop $fpod
}

redeploy_fluentd() {
  # redeploy fluentd
  oc label node --all logging-infra-fluentd=true

  # wait for fluentd to start
  wait_for_pod_ACTION start fluentd
}

TEST_DIVIDER="------------------------------------------"

# configure fluentd to just use the same ES instance for the copy
# cause messages to be written to a container - verify that ES contains
# two copies
# cause messages to be written to the system log - verify that OPS contains
# two copies

undeploy_fluentd

cfg=`mktemp`
# first, make sure copy is off
oc get daemonset logging-fluentd -o yaml | \
    sed '/- name: ES_COPY/,/value:/ s/value: .*$/value: "false"/' | \
    oc replace -f -

redeploy_fluentd

# run test to make sure fluentd is working normally - no copy
write_and_verify_logs 1 || {
    oc get events -o yaml > $ARTIFACT_DIR/all-events.yaml 2>&1
    exit 1
}

undeploy_fluentd

# save original daemonset config
origconfig=`mktemp`
oc get daemonset logging-fluentd -o yaml > $origconfig

cleanup() {
    # may have already been cleaned up
    if [ ! -f $origconfig ] ; then return 0 ; fi
    undeploy_fluentd
    # put back original configuration
    oc replace --force -f $origconfig
    rm -f $origconfig
    redeploy_fluentd
}
trap "cleanup" INT TERM EXIT

nocopy=`mktemp`
# strip off the copy settings, if any
sed '/_COPY/,/value/d' $origconfig > $nocopy
# for every ES_ or OPS_ setting, create a copy called ES_COPY_ or OPS_COPY_
envpatch=`mktemp`
sed -n '/^ *- env:/,/^ *image:/ {
/^ *image:/d
/^ *- env:/d
/name: K8S_HOST_URL/,/value/d
/name: .*JOURNAL.*/,/value/d
/name: .*BUFFER.*/,/value/d
/name: .*MUX.*/,/value/d
/name: FLUENTD_.*_LIMIT/,/valueFrom:/d
/resourceFieldRef:/,/containerName: fluentd-elasticsearch/d
/divisor:/,/resource: limits./d
s/ES_/ES_COPY_/
s/OPS_/OPS_COPY_/
p
}' $nocopy > $envpatch

# add the scheme, and turn on verbose
cat >> $envpatch <<EOF
        - name: ES_COPY
          value: "true"
        - name: ES_COPY_SCHEME
          value: https
        - name: OPS_COPY_SCHEME
          value: https
        - name: VERBOSE
          value: "true"
EOF

# add this back to the dc config
docopy=`mktemp`
cat $nocopy | \
    sed '/^ *- env:/r '$envpatch > $docopy

cat $docopy | \
    oc replace -f -

redeploy_fluentd
rm -f $envpatch $nocopy $docopy

write_and_verify_logs 2 || {
    oc get events -o yaml > $ARTIFACT_DIR/all-events.yaml 2>&1
    exit 1
}

# put back original configuration
oc replace --force -f $origconfig
rm -f $origconfig

write_and_verify_logs 1 || {
    oc get events -o yaml > $ARTIFACT_DIR/all-events.yaml 2>&1
    exit 1
}
