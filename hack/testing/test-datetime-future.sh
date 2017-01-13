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

ARTIFACT_DIR=${ARTIFACT_DIR:-${TMPDIR:-/tmp}/origin-aggregated-logging}
if [ ! -d $ARTIFACT_DIR ] ; then
    mkdir -p $ARTIFACT_DIR
fi

get_test_user_token

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
    if myhost=logging-es${ops} myproject=${INDEX_PREFIX}.operations mymessage=$uq expected=$expected myfield=systemd.u.SYSLOG_IDENTIFIER \
             wait_until_cmd_or_err test_count_expected test_count_err 20 ; then
        if [ -n "$VERBOSE" ] ; then
            echo good - found $expected records project ${INDEX_PREFIX}.operations for $uq
        fi
    else
        echo failed - test-datetime-future.sh: not found $expected records project ${INDEX_PREFIX}.operations for $uq
        rc=1
    fi

    if [ $rc -ne 0 ]; then
        echo test-datetime-future.sh: returning $rc ...
    fi
    return $rc
}

if [ -z "${USE_JOURNAL:-}" ] ; then
    docker_uses_journal() {
        # need to be able to handle cases like
        # OPTIONS='--log-driver=json-file ....' # or use --log-driver=journald
        grep -q "^OPTIONS='[^']*--log-driver=journald" /etc/sysconfig/docker
    }
else
    docker_uses_journal() {
        test $USE_JOURNAL = true
    }
fi

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

if docker_uses_journal ; then
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
