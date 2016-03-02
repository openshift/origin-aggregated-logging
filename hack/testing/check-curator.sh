#!/bin/bash

if [[ $VERBOSE ]]; then
  set -ex
else
  set -e
fi

if [[ $# -ne 1 || "$1" = "false" ]]; then
  # assuming not using OPS cluster
  CLUSTER="false"
else
  CLUSTER="$1"
  OPS="-ops"
fi

add_message_to_index() {
    # index is $1
    # message is $2
    # ops is $3
    message=${2:-"curatortest message"}
    if [ -z "$3" ] ; then
        host=logging-es
    else
        host=logging-es-ops
    fi
    ca=/etc/fluent/keys/ca
    cert=/etc/fluent/keys/cert
    key=/etc/fluent/keys/key
    url="https://${host}:9200/$1/curatortest/"
    oc exec $fpod -- curl -s --cacert $ca --cert $cert --key $key -XPOST "$url" -d '{
    "message" : "'"$message $3"'"
}' > /dev/null
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
        return 1
    fi
    return 0
}

create_indices() {
    myops="$1"
    set -- project-dev "$today" project-dev "$yesterday" project-qe "$today" project-qe "$lastweek" project-prod "$today" project-prod "$fourweeksago" .operations "$today" .operations "$twomonthsago" default-index "$today" default-index "$thirtydaysago"
    while [ -n "$1" ] ; do
        proj="$1" ; shift
        add_message_to_index "${proj}.$1" "$proj $1 message" $myops
        shift
    done
}

verify_indices() {
    myops=$2
    curout=`mktemp`
    oc exec $1 -- curator --host logging-es${myops} --use_ssl --certificate /etc/curator/keys/ca \
       --client-cert /etc/curator/keys/cert --client-key /etc/curator/keys/key --loglevel ERROR \
       show indices --all-indices > $curout 2>&1
    set -- project-dev "$today" project-dev "$yesterday" project-qe "$today" project-qe "$lastweek" project-prod "$today" project-prod "$fourweeksago" .operations "$today" .operations "$twomonthsago" default-index "$today" default-index "$thirtydaysago"
    rc=0
    while [ -n "$1" ] ; do
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
    fi
    rm -f $curout
    return $rc
}

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


basictest() {
    ops="$1"
    create_indices "$ops"

    # get current curator pod
    curpod=`get_running_pod curator${ops}`
    # show current indices
    echo current indices are:
    oc exec $curpod -- curator --host logging-es${ops} --use_ssl --certificate /etc/curator/keys/ca \
       --client-cert /etc/curator/keys/cert --client-key /etc/curator/keys/key --loglevel ERROR \
       show indices --all-indices
    # add the curator config yaml settings file
    curtest=`mktemp --suffix=.yaml`
    # calculate the runhour and runminute to run 5 minutes from now
    runhour=`date -u +%H --date="5 minutes hence"`
    runminute=`date -u +%M --date="5 minutes hence"`
    cat > $curtest <<EOF
.defaults:
  delete:
    days: 30
  runhour: $runhour
  runminute: $runminute
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
EOF
    oc delete secret curator-config${ops} || echo no such secret curator-config${ops} - ignore
    oc secrets new curator-config${ops} settings=$curtest
    oc volumes dc/logging-curator${ops} --add --type=secret --secret-name=curator-config${ops} --mount-path=/etc/curator --name=curator-config --overwrite
    # scale down dc
    oc scale --replicas=0 dc logging-curator${ops}
    # wait for pod to go away
    wait_for_pod_ACTION stop $curpod
    # scale up dc
    oc scale --replicas=1 dc logging-curator${ops}
    # wait for pod to start
    wait_for_pod_ACTION start curator${ops}
    # query ES
    curpod=`get_running_pod curator${ops}`
    verify_indices $curpod $ops

    # now, add back the same messages/indices and see if runhour and runminute are working
    create_indices $ops

    echo sleeping 5 minutes to see if runhour and runminute are working . . .
    sleep 300 # 5 minutes
    echo verify indices deletion again
    verify_indices $curpod $ops

    return 0
}

# test without ops cluster first
basictest || exit $?
if [ "$CLUSTER" = "true" ] ; then
    basictest "$OPS" || exit $?
fi
exit 0
