#!/bin/bash

if [ "${VERBOSE:-false}" = "true" ] ; then
  set -ex
else
  set -e
  # to make nounset happy
  VERBOSE=
fi
set -o nounset
set -o pipefail

if [[ $# -ne 1 || "$1" = "false" ]]; then
  # assuming not using OPS cluster
  CLUSTER="false"
else
  CLUSTER="$1"
  OPS="-ops"
fi

ARTIFACT_DIR=${ARTIFACT_DIR:-${TMPDIR:-/tmp}/origin-aggregated-logging}
if [ ! -d $ARTIFACT_DIR ] ; then
    mkdir -p $ARTIFACT_DIR
fi

add_message_to_index() {
    # index is $1
    # message is $2
    # ops is $3
    message=${2:-"curatortest message"}${3:-""}
    host=logging-es${3:-""}
    ca=/etc/fluent/keys/ca
    cert=/etc/fluent/keys/cert
    key=/etc/fluent/keys/key
    url="https://${host}:9200/$1/curatortest/"
    oc exec $fpod -- curl -s --cacert $ca --cert $cert --key $key -XPOST "$url" -d '{
    "message" : "'"$message"'"
}' > /dev/null
}

get_running_pod() {
    # $1 is component for selector
    oc get pods -l component=$1 | awk -v sel=$1 '$1 ~ sel && $3 == "Running" {print $1}'
}

get_error_pod() {
    # $1 is component for selector
    oc get pods -l component=$1 | awk -v sel=$1 '$1 ~ sel && ($3 == "Error" || $3 == "CrashLoopBackOff") {print $1}'
}

wait_for_pod_ACTION() {
    # action is $1 - start or stop
    # $2 - if action is stop, $2 is the pod name
    #    - if action is start, $2 is the component selector
    # $3 - if present, expect error - if stop, $2 may be empty, just return - if start, no error if pod cannot be started
    ii=120
    incr=10
    if [ $1 = start ] ; then
        curpod=`get_running_pod $2`
    else
        curpod=${2:-}
        if [ -z "${curpod:-}" -a -n "${3:-}" ] ; then
            return 0 # assume not running
        fi
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
        if [ -z "$curpod" ] ; then
            errpod=`get_error_pod $2`
            if [ -n "$errpod" ] ; then
                if [ -z "${2:-}" ] ; then
                    echo ERROR: pod $2 is in state Error
                    oc get pods > $ARTIFACT_DIR/curator-pods 2>&1
                    return 1
                fi
                return 0
            fi
        fi
    done
    if [ -z "${2:-}" ] ; then
        if [ $ii -le 0 ] ; then
            echo ERROR: pod $2 not in state $1 after 2 minutes
            oc get pods > $ARTIFACT_DIR/curator-pods 2>&1
            return 1
        fi
    fi
    return 0
}

wait_for_curator_run() {
    # curator pod is $1
    # $2 is the number of times "curator run finish" must occur in the curator log
    ii=120
    incr=1
    while [ $ii -gt 0 ] ; do
        count=`oc logs $1|grep -c "curator run finish" || :`
        if [ "$count" = $2 ] ; then
            return 0
        fi
        sleep $incr
        ii=`expr $ii - $incr`
    done
    echo ERROR: curator run not complete for pod $1 after 2 minutes
    date
    oc logs $1 > $ARTIFACT_DIR/$1.log 2>&1
    return 1
}

create_indices() {
    myops=${1:-""}
    set -- project-dev "$today" project-dev "$yesterday" project-qe "$today" project-qe "$lastweek" project-prod "$today" project-prod "$fourweeksago" .operations "$today" .operations "$twomonthsago" default-index "$today" default-index "$thirtydaysago" project2-qe "$today" project2-qe "$lastweek" project3-qe "$today" project3-qe "$lastweek"
    while [ -n "${1:-}" ] ; do
        proj="$1" ; shift
        add_message_to_index "${proj}.$1" "$proj $1 message" $myops
        shift
    done
}

verify_indices() {
    mycuratorpod=$1
    myops=${2:-""}
    curout=`mktemp`
    oc exec $1 -- curator --host logging-es${myops} --use_ssl --certificate /etc/curator/keys/ca \
       --client-cert /etc/curator/keys/cert --client-key /etc/curator/keys/key --loglevel ERROR \
       show indices --all-indices > $curout 2>&1
    set -- project-dev "$today" project-dev "$yesterday" project-qe "$today" project-qe "$lastweek" project-prod "$today" project-prod "$fourweeksago" .operations "$today" .operations "$twomonthsago" default-index "$today" default-index "$thirtydaysago" project2-qe "$today" project2-qe "$lastweek" project3-qe "$today" project3-qe "$lastweek"
    rc=0
    while [ -n "${1:-}" ] ; do
        proj="$1" ; shift
        idx="${proj}.$1"
        if [ "$1" = "$today" ] ; then
            # index must be present
            if grep \^"$idx"\$ $curout > /dev/null 2>&1 ; then
                echo good - index "$idx" is present
            else
                echo ERROR: index "$idx" is missing
                rc=1
            fi
        else
            # index must be absent
            if grep \^"$idx"\$ $curout > /dev/null 2>&1 ; then
                echo ERROR: index "$idx" was not deleted
                rc=1
            else
                echo good - index "$idx" is missing
            fi
        fi
        shift
    done
    if [ $rc -ne 0 ] ; then
        echo ERROR: The index list is:
        cat $curout
        oc logs $mycuratorpod > $ARTIFACT_DIR/$mycuratorpod.log 2>&1
    fi
    rm -f $curout
    return $rc
}

restart_curator() {
    # $1 - if present, expect errors
    # scale down dc
    oc scale --replicas=0 dc logging-curator${ops:-}
    # wait for pod to go away
    wait_for_pod_ACTION stop "$curpod" ${1:-}
    # scale up dc
    oc scale --replicas=1 dc logging-curator${ops:-}
    # wait for pod to start
    wait_for_pod_ACTION start curator${ops:-} ${1:-}
    # get new pod
    curpod=`get_running_pod curator${ops:-}`
}

uses_config_maps() {
    oc get dc logging-curator -o yaml | grep -q -i configmap:
}

update_config_and_restart() {
    # $1 - file holding configuration
    # $2 - if present, expect errors
    if uses_config_maps ; then
        # use configmap
        oc delete configmap logging-curator || :
        sleep 1
        if grep -q ^apiVersion: $1 ; then
            oc create -f $1 || : # oc get yaml dump, not a curator config file
        else
            oc create configmap logging-curator --from-file=config.yaml=$1
        fi
        sleep 1
    else
        # use secret volume mount
        oc delete secret curator-config${ops:-} || echo no such secret curator-config${ops:-} - ignore
        oc secrets new curator-config${ops:-} settings=$1
        oc volumes dc/logging-curator${ops:-} --add --type=secret --secret-name=curator-config${ops:-} --mount-path=/etc/curator --name=curator-config --overwrite
    fi
    restart_curator ${2:-}
}

if uses_config_maps ; then
    origconfig=`mktemp`
    oc get configmap logging-curator -o yaml > $origconfig || :
fi

cleanup() {
    if [ -n "${origconfig:-}" -a -f $origconfig ] ; then
        oc delete configmap logging-curator || :
        sleep 1
        oc create -f $origconfig || :
        sleep 1
    else
        oc delete secret curator-config || :
        oc delete secret curator-config-ops || :
        oc volumes dc/logging-curator --delete --type=secret --secret-name=curator-config --name=curator-config || :
        oc volumes dc/logging-curator-ops --delete --type=secret --secret-name=curator-config-ops --name=curator-config || :
    fi
    rm -f $origconfig
    restart_curator errors
}
trap "cleanup" INT TERM EXIT

# use the fluentd credentials to add records and indices for these projects
# oc get secret logging-fluentd --template='{{.data.ca}}' | base64 -d > ca-fluentd
# ca=./ca-fluentd
# oc get secret logging-fluentd --template='{{.data.key}}' | base64 -d > key-fluentd
# key=./key-fluentd
# oc get secret logging-fluentd --template='{{.data.cert}}' | base64 -d > cert-fluentd
# cert=./cert-fluentd
fpod=`oc get pods -l component=fluentd | awk '/fluentd/ {print $1}'`
tf='%Y.%m.%d'
today=`date -u +"$tf"`
yesterday=`date -u +"$tf" --date=yesterday`
lastweek=`date -u +"$tf" --date="last week"`
fourweeksago=`date -u +"$tf" --date="4 weeks ago"`
thirtydaysago=`date -u +"$tf" --date="30 days ago"`
# projects:
# project-dev-YYYY.mm.dd delete 24 hours
# project-qe-YYYY.mm.dd delete 7 days
# project-prod-YYYY.mm.dd delete 4 weeks
# .operations-YYYY.mm.dd delete 2 months

# where "yesterday", "today", etc. are the dates in UTC in YYYY.mm.dd format
# When is a month not a month?  When it is a curator month!  When you use
# month based trimming, curator starts counting at the first day of the
# current month, not the current day of the current month.  For example, if
# today is April 15, and you want to delete indices that are 2 months older
# than today (--time-unit months --older-than 2 --timestring %Y.%m.%d),
# curator doesn't delete indices that are dated older than February 15, it
# deletes indices older than _February 1_.  That is, it goes back to the
# first day of the current month, _then_ goes back two whole months from
# that date.
# If you want to be exact with curator, it is best to use
# day based trimming e.g. --time-unit days --older-than 60 --timestring %Y.%m.%d
# There is apparently no way to tell curator to delete indices exactly N
# months older than the current date.
twomonthsago=`date -u +"$tf" --date="$(date +%Y-%m-1) -2 months -1 day"`
# project-dev-yesterday project-dev-today
# project-qe-lastweek project-qe-today
# project-prod-4weeksago project-today
# .operations-2monthsago .operations-today

TEST_DIVIDER="------------------------------------------"

test_project_name_errors() {
    curpod=`get_running_pod curator`
    curtest=`mktemp --suffix=.yaml`
    cat > $curtest <<EOF
this-project-name-is-far-far-too-long-this-project-name-is-far-far-too-long-this-project-name-is-far-far-too-long-this-project-name-is-far-far-too-long:
  delete:
    days: 1
EOF
    update_config_and_restart $curtest errors
    sleep 1
    rc=0
    # curator pod should be in error state
    errpod=`get_error_pod curator`
    if [ -z "${errpod:-}" ] ; then
        echo Error: the curator pod should be in the error state
        get_running_pod curator
        rc=1
    fi
    # see if the right message is in the log
    if [ $rc = 0 ] && oc logs $errpod 2>&1 | grep -q "The project name length must be less than or equal to" ; then
        : # correct
    else
        echo Error: did not find the correct error message
        oc logs $errpod
        rc=1
    fi
    if [ $rc = 0 ] ; then
        cat > $curtest <<EOF
-BOGUS^PROJECT^NAME:
  delete:
    days: 1
EOF
        update_config_and_restart $curtest errors
        sleep 1
        # curator pod should be in error state
        errpod=`get_error_pod curator`
        if [ -z "${errpod:-}" ] ; then
            echo Error: the curator pod should be in the error state
            get_running_pod curator
            rc=1
        fi
        # see if the right message is in the log
        if [ $rc = 0 ] && oc logs $errpod 2>&1 | grep -q "The project name must match this regex" ; then
            : # correct
        else
            echo Error: did not find the correct error message
            oc logs $errpod
            rc=1
        fi
    fi
    if [ $rc = 0 ] ; then
        update_config_and_restart $origconfig errors
    fi
    return $rc
}

basictest() {
    ops=${1:-""}
    create_indices "$ops"

    sleeptime=300 # seconds
    # get current curator pod
    curpod=`get_running_pod curator${ops}`
    # show current indices, 1st deletion is triggered by restart curator pod; 2nd deletion is triggered by runhour and runminute
    echo current indices before 1st deletion are:
    oc exec $curpod -- curator --host logging-es${ops} --use_ssl --certificate /etc/curator/keys/ca \
       --client-cert /etc/curator/keys/cert --client-key /etc/curator/keys/key --loglevel ERROR \
       show indices --all-indices
    # add the curator config yaml settings file
    curtest=`mktemp --suffix=.yaml`
    # see what the current time and timezone are in the curator pod
    oc exec $curpod -- date
    # calculate the runhour and runminute to run 5 minutes from now
    # There is apparently a bug in el7 - this doesn't work:
    # date +%H --date="TZ=\"Region/City\" 5 minutes hence"
    ## date: invalid date ‘TZ="Region/City" 5 minutes hence’
    # so for now, just use UTC
    #tz=`timedatectl | awk '/Time zone:/ {print $3}'`
    tz=UTC
    runhour=`date +%H --date="TZ=\"$tz\" $sleeptime seconds hence"`
    runminute=`date +%M --date="TZ=\"$tz\" $sleeptime seconds hence"`
    cat > $curtest <<EOF
.defaults:
  delete:
    days: 30
  runhour: $runhour
  runminute: $runminute
  timezone: $tz
project-dev:
  delete:
    days: 1
project-qe:
  delete:
    days: 7
project-prod:
  delete:
    weeks: 4
.operations:
  delete:
    months: 2
project2-qe:
  delete:
    days: 7
project3-qe:
  delete:
    days: 7
EOF
    update_config_and_restart $curtest
    # wait for curator run 1 to finish
    wait_for_curator_run $curpod 1
    # show current indices
    echo current indices after 1st deletion are:
    oc exec $curpod -- curator --host logging-es${ops} --use_ssl --certificate /etc/curator/keys/ca \
       --client-cert /etc/curator/keys/cert --client-key /etc/curator/keys/key --loglevel ERROR \
       show indices --all-indices
    verify_indices $curpod $ops

    # now, add back the same messages/indices and see if runhour and runminute are working
    create_indices $ops
    # show current indices
    echo current indices before 2nd deletion are:
    oc exec $curpod -- curator --host logging-es${ops} --use_ssl --certificate /etc/curator/keys/ca \
       --client-cert /etc/curator/keys/cert --client-key /etc/curator/keys/key --loglevel ERROR \
       show indices --all-indices

    echo sleeping $sleeptime seconds to see if runhour and runminute are working . . .
    sleep $sleeptime
    # wait for curator run 2 to finish
    wait_for_curator_run $curpod 2
    echo verify indices deletion again
    # show current indices
    echo current indices after 2nd deletion are:
    oc exec $curpod -- curator --host logging-es${ops} --use_ssl --certificate /etc/curator/keys/ca \
       --client-cert /etc/curator/keys/cert --client-key /etc/curator/keys/key --loglevel ERROR \
       show indices --all-indices
    verify_indices $curpod $ops

    return 0
}

# test without ops cluster first
test_project_name_errors
basictest
if [ "$CLUSTER" = "true" ] ; then
    basictest "$OPS"
fi
exit 0
