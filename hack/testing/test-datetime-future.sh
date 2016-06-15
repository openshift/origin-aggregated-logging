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

    # generate a log message 1 hour in the future
    dt=`date -u +"%b %d %H:%M:%S" --date="1 hour hence"`
    uq=`uuidgen`
    # NOTE: can't use `logger` for this because we need complete control over the date and format
    # so have to use sudo to write directly to /var/log/messages
    echo "$dt localhost $uq: $uq message from test-datetime-future" | sudo tee -a /var/log/messages > /dev/null

    # get current kibana pod
    kpod=`get_running_pod kibana`
    if [ -z "$kpod" ] ; then
        echo Error: no kibana pod found
        oc get pods
        return 1
    fi

    rc=0
    # wait for message to show up in the ops log
    if myhost=logging-es${ops} myproject=.operations mymessage=$uq expected=$expected myfield=ident \
             wait_until_cmd_or_err test_count_expected test_count_err 20 ; then
        if [ -n "$VERBOSE" ] ; then
            echo good - found $expected records project .operations for $uq
        fi
    else
        rc=1
    fi

    return $rc
}

TEST_DIVIDER="------------------------------------------"

# make sure the host/node TZ is the same as the fluentd pod
fpod=`get_running_pod fluentd`
nodetz=`date +%z`
podtz=`oc exec $fpod -- date +%z`
if [ x"$nodetz" = x"$podtz" ] ; then
    echo Good - node timezone $nodetz `date +%Z` is equal to the fluentd pod timezone
else
    echo Error - node timezone $nodetz is not equal to the fluentd pod timezone $podtz
    exit 1
fi

if [ "${USE_JOURNAL:-false}" = "true" ] ; then
    # don't need to test the /var/log/messages code
    echo The rest of the test is not applicable when using the journal - skipping
    exit 0
fi

cleanup() {
    rc=$?
    if [ -n "${before:-}" -a -f "${before:-}" ] ; then
        if [ "$rc" != "0" ] ; then
            echo fluentd log before:
            cat $before
            echo ""
        fi
        rm -f $before
    fi
    if [ -n "${after:-}" -a -f "${after:-}" ] ; then
        if [ "$rc" != "0" ] ; then
            echo fluentd log after:
            cat $after
            echo ""
        fi
        rm -f $after
    fi
}
trap "cleanup" INT TERM EXIT

# save log of fluentd before test
before=`mktemp`
oc logs $fpod > $before

# write syslog message and verify in ES
write_and_verify_logs 1

after=`mktemp`
oc logs $fpod > $after

diff $before $after
