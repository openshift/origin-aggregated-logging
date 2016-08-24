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

# not used for now, but in case
INDEX_PREFIX=
PROJ_PREFIX=project.

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
    oc exec $1 -c kibana -- curl --connect-timeout 1 -s -k \
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
    expected=1
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
    if myhost=logging-es myproject=${PROJ_PREFIX}test mymessage=$logmessage expected=$expected \
             wait_until_cmd_or_err test_count_expected test_count_err 60 ; then
        if [ -n "$VERBOSE" ] ; then
            echo good - found $expected records project test for $logmessage
        fi
    else
        rc=1
    fi

    if [ $rc = "0" ] ; then
        # get the record - verify that the "undefined" field contains the undefined
        # members
        # verify that there are no fields with empty values
        curl_es_from_kibana $kpod logging-es ${PROJ_PREFIX}test _search message $logmessage | \
            python test-undefined.py
    fi

    if myhost=logging-es${ops} myproject=${INDEX_PREFIX}.operations mymessage=$logmessage2 expected=$expected myfield=ident \
             wait_until_cmd_or_err test_count_expected test_count_err 60 ; then
        if [ -n "$VERBOSE" ] ; then
            echo good - found $expected records project .operations for $logmessage2
        fi
    else
        rc=1
    fi

    if [ $rc = "0" ] ; then
        # get the record - verify that the "undefined" field contains the undefined
        # members
        # verify that there are no fields with empty values
        curl_es_from_kibana $kpod logging-es${ops} ${INDEX_PREFIX}.operations _search message $logmessage2 | \
            python test-undefined.py
    fi

    return $rc
}

remove_test_volume() {
    oc get template logging-fluentd-template -o json | \
        python -c 'import json, sys; obj = json.loads(sys.stdin.read()); vm = obj["objects"][0]["spec"]["template"]["spec"]["containers"][0]["volumeMounts"]; obj["objects"][0]["spec"]["template"]["spec"]["containers"][0]["volumeMounts"] = [xx for xx in vm if xx["name"] != "undefinedtest"]; vs = obj["objects"][0]["spec"]["template"]["spec"]["volumes"]; obj["objects"][0]["spec"]["template"]["spec"]["volumes"] = [xx for xx in vs if xx["name"] != "undefinedtest"]; print json.dumps(obj, indent=2)' | \
        oc replace -f -
}

# takes json input, removes the "undefinedtest" volume and volumeMount, returns
# json output
# oc get ... -o json | add_test_volume | oc replace -f -
# $1 is the local file to use for the volume hostPath
add_test_volume() {
    oc get template logging-fluentd-template -o json | \
        python -c 'import json, sys; obj = json.loads(sys.stdin.read()); obj["objects"][0]["spec"]["template"]["spec"]["containers"][0]["volumeMounts"].append({"name": "undefinedtest", "mountPath": "/etc/fluent/configs.d/openshift/filter-pre-undefined-test.conf", "readOnly": True}); obj["objects"][0]["spec"]["template"]["spec"]["volumes"].append({"name": "undefinedtest", "hostPath": {"path": "'$1'"}}); print json.dumps(obj, indent=2)' | \
        oc replace -f -
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
testip=$(oc get -n test --output-version=v1beta3 --template="{{ .spec.portalIP }}" service frontend)
testport=5432

# configure fluentd with a test filter that adds undefined and empty fields/hashes
# verify that undefined fields are stored in a top level field with a hash value
# the hash holds all of the other top level fields that are undefined
# also verify that the output contains no empty fields, including empty hashes

fpod=`get_running_pod fluentd`

# first, make sure the undefined test filter is not being used
remove_test_volume
# add the test volume
cfg=`mktemp`
cat > $cfg <<EOF
<filter **>
  @type record_transformer
  <record>
    undefined1 undefined1
    empty1 ""
    undefined2 {"undefined2":"undefined2","":""}
    undefined3 {"":""}
  </record>
</filter>
EOF
add_test_volume $cfg

cleanup() {
    remove_test_volume
    rm -f $cfg
    restart_fluentd
}
trap "cleanup" INT TERM EXIT

restart_fluentd
fpod=`get_running_pod fluentd`

# run test to make sure fluentd is working normally
write_and_verify_logs || {
    oc get events -o yaml > $ARTIFACT_DIR/all-events.yaml 2>&1
    exit 1
}
