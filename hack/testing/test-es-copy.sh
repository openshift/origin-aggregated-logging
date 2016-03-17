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

write_and_verify_logs() {
    # expected number of matches
    expected=$1

    # write a log message to the test app
    logmessage=`uuidgen`
    curl -s http://$testip:$testport/$logmessage > /dev/null 2>&1 || echo will generate a 404

    # write a message to the system log
    logmessage2=`uuidgen`
    logger -i -p local6.info -t $logmessage2 $logmessage2

    # wait a bit for fluentd + es to digest
    sleep 20

    # get current kibana pod
    kpod=`get_running_pod kibana`
    if [ -z "$kpod" ] ; then
        echo Error: no kibana pod found
        oc get pods
        return 1
    fi

    rc=0
    # count the matching records
    nrecs=`oc exec $kpod -- curl -s -k --cert /etc/kibana/keys/cert --key /etc/kibana/keys/key \
           https://logging-es:9200/test*/_count\?q=message:$logmessage | \
           python -c 'import json; import sys; print json.loads(sys.stdin.read())["count"]'`
    if [ "$nrecs" = $expected ] ; then
        if [ -n "$VERBOSE" ] ; then
            echo good - found $expected records for $logmessage
        fi
    else
        echo Error: found $nrecs for $logmessage - expected $expected
        oc exec $kpod -- curl -s -k --cert /etc/kibana/keys/cert --key /etc/kibana/keys/key \
           https://logging-es:9200/test*/_count\?q=message:$logmessage | python -mjson.tool
        oc exec $kpod -- curl -s -k --cert /etc/kibana/keys/cert --key /etc/kibana/keys/key \
           https://logging-es:9200/test*/_search\?q=message:$logmessage | python -mjson.tool
        rc=1
    fi

    nrecs=`oc exec $kpod -- curl -s -k --cert /etc/kibana/keys/cert --key /etc/kibana/keys/key \
           https://logging-es${ops}:9200/.operations*/_count\?q=ident:$logmessage2 | \
           python -c 'import json; import sys; print json.loads(sys.stdin.read())["count"]'`
    if [ "$nrecs" = $expected ] ; then
        if [ -n "$VERBOSE" ] ; then
            echo good - found $expected records for $logmessage2
        fi
    else
        echo Error: found $nrecs for $logmessage2 - expected $expected
        oc exec $kpod -- curl -s -k --cert /etc/kibana/keys/cert --key /etc/kibana/keys/key \
           https://logging-es${ops}:9200/.operations*/_count\?q=ident:$logmessage2 | python -mjson.tool
        oc exec $kpod -- curl -s -k --cert /etc/kibana/keys/cert --key /etc/kibana/keys/key \
           https://logging-es${ops}:9200/.operations*/_search\?q=ident:$logmessage2 | python -mjson.tool
        rc=1
    fi

    return $rc
}

TEST_DIVIDER="------------------------------------------"

# this is the OpenShift origin sample app
testip=$(oc get -n test --output-version=v1beta3 --template="{{ .spec.portalIP }}" service frontend)
testport=5432

# configure fluentd to just use the same ES instance for the copy
# cause messages to be written to a container - verify that ES contains
# two copies
# cause messages to be written to the system log - verify that OPS contains
# two copies

fpod=`get_running_pod fluentd`

# save original template config
origconfig=`mktemp`
oc get template logging-fluentd-template -o yaml > $origconfig

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

# add the scheme
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

# delete daemonset which also stops fluentd
oc delete daemonset logging-fluentd
# wait for fluentd to stop
wait_for_pod_ACTION stop $fpod
# create the daemonset which will also start fluentd
oc process logging-fluentd-template | oc create -f -
# wait for fluentd to start
wait_for_pod_ACTION start fluentd

fpod=`get_running_pod fluentd`

write_and_verify_logs 2 || {
    oc get events -o yaml > $ARTIFACT_DIR/all-events.yaml 2>&1
    exit 1
}

# put back original configuration
oc replace --force -f $origconfig
rm -f $origconfig

# delete daemonset which also stops fluentd
oc delete daemonset logging-fluentd
# wait for fluentd to stop
wait_for_pod_ACTION stop $fpod
# create the daemonset which will also start fluentd
oc process logging-fluentd-template | oc create -f -
# wait for fluentd to start
wait_for_pod_ACTION start fluentd

fpod=`get_running_pod fluentd`

write_and_verify_logs 1 || {
    oc get events -o yaml > $ARTIFACT_DIR/all-events.yaml 2>&1
    exit 1
}
