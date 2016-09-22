#!/bin/bash

if [[ $VERBOSE ]]; then
  set -ex
else
  set -e
  VERBOSE=
fi
set -o nounset
set -o pipefail

if [[ $# -ne 1 || "$1" = "false" ]]; then
  # assuming not using OPS cluster
  CLUSTER="false"
  ops=
else
  CLUSTER="$1"
  ops="-ops"
fi

ARTIFACT_DIR=${ARTIFACT_DIR:-${TMPDIR:-/tmp}/origin-aggregated-logging}
if [ ! -d $ARTIFACT_DIR ] ; then
    mkdir -p $ARTIFACT_DIR
fi

# $1 - shell command or function to call to test if wait is over -
#      this command/function should return true if the condition
#      has been met, or false if still waiting for condition to be met
# $2 - shell command or function to call if we timed out for error handling
# $3 - timeout in seconds - should be a multiple of $4 (interval)
# $4 - loop interval in seconds
wait_until_cmd_or_err() {
    let ii=$3
    interval=${4:-1}
    while [ $ii -gt 0 ] ; do
        $1 && break
        sleep $interval
        let ii=ii-$interval
    done
    if [ $ii -le 0 ] ; then
        $2
        return 1
    fi
    return 0
}

get_running_pod() {
    # $1 is component for selector
    oc get pods -l component=$1 | awk -v sel=$1 '$1 ~ sel && $3 == "Running" {print $1}'
}

wait_for_pod_ACTION() {
    # action is $1 - start or stop
    # $2 - if action is stop, $2 is the pod name
    #    - if action is start, $2 is the component selector
    ii=120
    incr=10
    if [ $1 = start ] ; then
        curpod=`get_running_pod $2`
    else
        curpod=$2
    fi
    while [ $ii -gt 0 ] ; do
        if [ $1 = stop ] && oc describe pod/$curpod > /dev/null 2>&1 ; then
            if [ -n "$VERBOSE" ] ; then
                echo pod $curpod still running
            fi
        elif [ $1 = start ] && [ -z "$curpod" ] ; then
            if [ -n "$VERBOSE" ] ; then
                echo pod for component=$2 not running yet
            fi
        else
            break # pod is either started or stopped
        fi
        sleep $incr
        ii=`expr $ii - $incr`
        if [ $1 = start ] ; then
            curpod=`get_running_pod $2`
        fi
    done
    if [ $ii -le 0 ] ; then
        echo ERROR: pod $2 not in state $1 after 2 minutes
        oc get pods
        return 1
    fi
    return 0
}

# $1 - kibana pod name
# $2 - es hostname (e.g. logging-es or logging-es-ops)
# $3 - project name (e.g. logging, test, .operations, etc.)
# $4 - _count or _search
# $5 - field to search
# $6 - search string
# stdout is the JSON output from Elasticsearch
# stderr is curl errors
curl_es_from_kibana() {
    oc exec $1 -- curl --connect-timeout 1 -s -k \
       --cert /etc/kibana/keys/cert --key /etc/kibana/keys/key \
       https://${2}:9200/${3}*/${4}\?q=${5}:${6}
}

# stdin is JSON output from Elasticsearch for _count search
# stdout is the integer count
# stderr is JSON parsing errors if bogus input (i.e. search error, empty JSON)
get_count_from_json() {
    python -c 'import json, sys; print json.loads(sys.stdin.read())["count"]'
}

# return true if the actual count matches the expected count, false otherwise
test_count_expected() {
    myfield=${myfield:-message}
    nrecs=`curl_es_from_kibana $kpod $myhost $myproject _count $myfield $mymessage | \
           get_count_from_json`
    test "$nrecs" = $expected
}

# display an appropriate error message if the expected count did not match
# the actual count
test_count_err() {
    myfield=${myfield:-message}
    nrecs=`curl_es_from_kibana $kpod $myhost $myproject _count $myfield $mymessage | \
           get_count_from_json`
    echo Error: found $nrecs for project $myproject message $mymessage - expected $expected
    for thetype in _count _search ; do
        curl_es_from_kibana $kpod $myhost $myproject $thetype $myfield $mymessage | python -mjson.tool
    done
}

write_and_verify_logs() {
    # expected number of matches
    expected=$1

    # write a log message to the test app
    logmessage=`uuidgen`
    curl --connect-timeout 1 -s http://$testip:$testport/$logmessage > /dev/null 2>&1 || echo will generate a 404

    # write a message to the system log
    logmessage2=`uuidgen`
    logger -i -p local6.info -t $logmessage2 $logmessage2

    # get current kibana pod
    kpod=`get_running_pod kibana`
    if [ -z "$kpod" ] ; then
        echo Error: no kibana pod found
        oc get pods
        return 1
    fi

    rc=0
    # poll for logs to show up
    if myhost=logging-es myproject=test mymessage=$logmessage expected=$expected \
             wait_until_cmd_or_err test_count_expected test_count_err 20 ; then
        if [ -n "$VERBOSE" ] ; then
            echo good - found $expected records project test for $logmessage
        fi
    else
        rc=1
    fi

    if myhost=logging-es${ops} myproject=.operations mymessage=$logmessage2 expected=$expected myfield=ident \
             wait_until_cmd_or_err test_count_expected test_count_err 20 ; then
        if [ -n "$VERBOSE" ] ; then
            echo good - found $expected records project .operations for $logmessage2
        fi
    else
        rc=1
    fi

    return $rc
}

restart_fluentd() {
    # delete daemonset which also stops fluentd
    oc delete daemonset logging-fluentd
    # wait for fluentd to stop
    wait_for_pod_ACTION stop $fpod
    # create the daemonset which will also start fluentd
    oc process logging-fluentd-template | oc create -f -
    # wait for fluentd to start
    wait_for_pod_ACTION start fluentd
}

TEST_DIVIDER="------------------------------------------"

# this is the OpenShift origin sample app
testip=$(oc get -n test --output-version=v1beta3 --template="{{ .spec.clusterIP }}" service frontend)
testport=5432

# configure fluentd to just use the same ES instance for the copy
# cause messages to be written to a container - verify that ES contains
# two copies
# cause messages to be written to the system log - verify that OPS contains
# two copies

fpod=`get_running_pod fluentd`

# first, make sure copy is off
cfg=`mktemp`
oc get template logging-fluentd-template -o yaml | \
    sed '/- name: ES_COPY/,/value:/ s/value: .*$/value: "false"/' | \
    oc replace -f -
restart_fluentd
fpod=`get_running_pod fluentd`

# save original template config
origconfig=`mktemp`
oc get template logging-fluentd-template -o yaml > $origconfig

# run test to make sure fluentd is working normally - no copy
write_and_verify_logs 1 || {
    oc get events -o yaml > $ARTIFACT_DIR/all-events.yaml 2>&1
    exit 1
}

cleanup() {
    # may have already been cleaned up
    if [ ! -f $origconfig ] ; then return 0 ; fi
    # put back original configuration
    oc replace --force -f $origconfig
    rm -f $origconfig
    restart_fluentd
}
trap "cleanup" INT TERM EXIT

nocopy=`mktemp`
# strip off the copy settings, if any
sed '/_COPY/,/value/d' $origconfig > $nocopy
# for every ES_ or OPS_ setting, create a copy called ES_COPY_ or OPS_COPY_
envpatch=`mktemp`
sed -n '/^        - env:/,/^          image:/ {
/^          image:/d
/^        - env:/d
/name: K8S_HOST_URL/,/value/d
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
cat $nocopy | \
    sed '/^        - env:/r '$envpatch | \
    oc replace -f -

rm -f $envpatch $nocopy

restart_fluentd
fpod=`get_running_pod fluentd`

write_and_verify_logs 2 || {
    oc get events -o yaml > $ARTIFACT_DIR/all-events.yaml 2>&1
    exit 1
}

# put back original configuration
oc replace --force -f $origconfig
rm -f $origconfig

restart_fluentd
fpod=`get_running_pod fluentd`

write_and_verify_logs 1 || {
    oc get events -o yaml > $ARTIFACT_DIR/all-events.yaml 2>&1
    exit 1
}
