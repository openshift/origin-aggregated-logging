#! /bin/bash

# test by having a fluentd forward securely to another fluentd (and not ES)
# have that second fluentd send logs to ES
# verify the same way we do now (for ES copy)
# need to create a custom configmap for both fluentd?

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

oc login --username=kibtest --password=kibtest
test_token="$(oc whoami -t)"
test_name="$(oc whoami)"
test_ip="127.0.0.1"
oc login --username=system:admin

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

wait_for_pod_action() {
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

cleanup_forward() {

  # Clean up only if it's still around
  oc delete daemonset/logging-forward-fluentd || :

  # Revert configmap if we haven't yet
  if [ -n "$(oc get configmap/logging-fluentd -o yaml | grep '<match \*\*>')" ]; then
    oc get configmap/logging-fluentd -o yaml | sed -e '/<match \*\*>/ d' \
        -e '/@include configs\.d\/user\/secure-forward\.conf/ d' \
        -e '/<\/match>/ d' | oc replace -f -
  fi

  oc patch configmap/logging-fluentd --type=json --patch '[{ "op": "replace", "path": "/data/secure-forward.conf", "value": "\
# @type secure_forward\n\
# self_hostname forwarding-${HOSTNAME}\n\
# shared_key aggregated_logging_ci_testing\n\
#  secure no\n\
#  <server>\n\
#   host ${FLUENTD_FORWARD}\n\
#   port 24284\n\
#  </server>"}]' || :

}

update_current_fluentd() {
  # this will update it so the current fluentd does not send logs to an ES host
  # but instead forwards to the forwarding fluentd

  # undeploy fluentd
  oc label node --all logging-infra-fluentd-

  wait_for_pod_action stop $fpod

  # edit so we don't send to ES
  oc get configmap/logging-fluentd -o yaml | sed '/## matches/ a\
      <match **>\
        @include configs.d/user/secure-forward.conf\
      </match>' | oc replace -f -

  POD=$(oc get pods -l component=forward-fluentd -o name)
  FLUENTD_FORWARD=$(oc get $POD --template='{{.status.podIP}}')

  # update configmap secure-forward.conf
  oc patch configmap/logging-fluentd --type=json --patch '[{ "op": "replace", "path": "/data/secure-forward.conf", "value": "\
  @type secure_forward\n\
  self_hostname forwarding-${HOSTNAME}\n\
  shared_key aggregated_logging_ci_testing\n\
  secure no\n\
  <server>\n\
   host '${FLUENTD_FORWARD}'\n\
   port 24284\n\
  </server>"}]'

  # redeploy fluentd
  oc label node --all logging-infra-fluentd=true

  # wait for fluentd to start
  wait_for_pod_action start fluentd
}

create_forwarding_fluentd() {
 # create forwarding configmap named "logging-forward-fluentd"
 oc create configmap logging-forward-fluentd \
    --from-file=fluent.conf=../templates/forward-fluent.conf

 # create forwarding daemonset
  oc get template/logging-fluentd-template -o yaml | \
    sed -e 's/logging-infra-fluentd: "true"/logging-infra-forward-fluentd: "true"/' \
        -e 's/name: logging-fluentd/name: logging-forward-fluentd/' \
        -e 's/ fluentd/ forward-fluentd/' \
        -e '/image:/ a \
          ports: \
            - containerPort: 24284' | \
    oc new-app -f -

  oc label node --all logging-infra-forward-fluentd=true

  # wait for fluentd to start
  wait_for_pod_action start forward-fluentd
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
       -H "X-Proxy-Remote-User: $test_name" -H "Authorization: Bearer $test_token" -H "X-Forwarded-For: 127.0.0.1" \
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
             wait_until_cmd_or_err test_count_expected test_count_err 60 ; then
        if [ -n "$VERBOSE" ] ; then
            echo good - found $expected records project test for $logmessage
        fi
    else
        rc=1
    fi

    if myhost=logging-es${ops} myproject=.operations mymessage=$logmessage2 expected=$expected myfield=ident \
             wait_until_cmd_or_err test_count_expected test_count_err 60 ; then
        if [ -n "$VERBOSE" ] ; then
            echo good - found $expected records project .operations for $logmessage2
        fi
    else
        rc=1
    fi

    return $rc
}

restart_fluentd() {
    oc label node --all logging-infra-fluentd-
    # wait for fluentd to stop
    wait_for_pod_action stop $fpod
    # create the daemonset which will also start fluentd
    oc label node --all logging-infra-fluentd=true
    # wait for fluentd to start
    wait_for_pod_action start fluentd
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

# run test to make sure fluentd is working normally - no forwarding
write_and_verify_logs 1 || {
    oc get events -o yaml > $ARTIFACT_DIR/all-events.yaml 2>&1
    exit 1
}

cleanup() {
    # put back original configuration
    cleanup_forward
    restart_fluentd
}
trap "cleanup" INT TERM EXIT

create_forwarding_fluentd
update_current_fluentd

fpod=`get_running_pod fluentd`

write_and_verify_logs 1 || {
    oc get events -o yaml > $ARTIFACT_DIR/all-events.yaml 2>&1
    exit 1
}

# put back original configuration
cleanup
fpod=`get_running_pod fluentd`

write_and_verify_logs 1 || {
    oc get events -o yaml > $ARTIFACT_DIR/all-events.yaml 2>&1
    exit 1
}
