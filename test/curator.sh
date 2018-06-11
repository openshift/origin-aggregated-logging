#!/bin/bash

# This is a test suite for the curator functionality
# It will first test that curator catches and reports
# various types of configuration errors.
# It will then create several dated indices in Elasticsearch
# and verify that they are correctly deleted or preserved.
# If the ops cluster is enabled, it will test curator-ops
# as well.

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::util::environment::use_sudo

os::test::junit::declare_suite_start "test/curator"

curl_output() {
    python -mjson.tool | artifact_out > /dev/null 2>&1
}

add_message_to_index() {
    local index="$1"
    local message="${2:-'curatortest mesage'}"
    local essvc="$3"
    curl_es "$essvc" "/$index/curatortest/" -XPOST -d '{
    "message" : "'${message}${3}'"
}' | curl_output
}

delete_indices() {
    local essvc="$1"
    curl_es $essvc "/*.curatortest.*" -XDELETE | curl_output
}

skip_list=("^\." "^default")

create_indices() {
    local essvc=$1
    set -- project-dev "$today" project-dev "$yesterday" project-qe "$today" project-qe "$lastweek" project-prod "$today" project-prod "$fourweeksago" .operations "$today" .operations "$twomonthsago" default-index "$today" default-index "$thirtyonedaysago" project2-qe "$today" project2-qe "$lastweek" project3-qe "$today" project3-qe "$lastweek"
    while [ -n "${1:-}" ] ; do
        local proj="$1" ; shift
        local this_proj="project.${proj}"
        for skip in ${skip_list[*]} ; do
            if [ `expr ${proj} : "$skip"` -gt 0 ]; then
                this_proj="${proj}"
                break
            fi
        done
        add_message_to_index "${this_proj}.curatortest.$1" "$this_proj $1 message" $essvc
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
    cat $curout | artifact_out
    set -- project-dev "$today" project-dev "$yesterday" project-qe "$today" project-qe "$lastweek" project-prod "$today" project-prod "$fourweeksago" .operations "$today" .operations "$twomonthsago" default-index "$today" default-index "$thirtyonedaysago" project2-qe "$today" project2-qe "$lastweek" project3-qe "$today" project3-qe "$lastweek"
    rc=0
    while [ -n "${1:-}" ] ; do
        proj="$1" ; shift
        this_idx="project.${proj}.curatortest.$1"
        for skip in ${skip_list[*]} ; do
            if [ `expr ${proj} : "$skip"` -gt 0 ]; then
                this_idx="${proj}.curatortest.$1"
                break
            fi
        done
        if [ "$1" = "$today" ] ; then
            # index must be present
            if grep -q \^"$this_idx"\$ $curout ; then
                artifact_log good - index $this_idx is present
            else
                os::log::error index $this_idx is missing
                rc=1
            fi
        else
            # index must be absent
            if grep -q \^"$this_idx"\$ $curout ; then
                os::log::error index $this_idx was not deleted
                rc=1
            else
                artifact_log good - index $this_idx is missing
            fi
        fi
        shift
    done
    rm -f $curout
    return $rc
}

stop_curator() {
    local curpod=$1
    oc scale --replicas=0 dc/logging-curator${ops:-} 2>&1 | artifact_out
    os::cmd::try_until_failure "oc get pod $curpod > /dev/null 2>&1" $(( 60 * second ))
}

restart_curator() {
    # $1 - if present, expect errors
    # redeploy dc
    # if there is a deployment already in progress, do not redeploy
    if oc rollout status --watch=false dc/logging-curator${ops:-} 2>&1 | grep -q "successfully rolled out" ; then
        oc rollout status --watch=false dc/logging-curator${ops:-} 2>&1 | artifact_out
        oc rollout latest dc/logging-curator${ops:-} 2>&1 | artifact_out
    else
        oc rollout status --watch=true dc/logging-curator${ops:-} 2>&1 | artifact_out # already in progress
    fi
    if [ -n "${1:-}" ] ; then
        oc scale --replicas=1 dc/logging-curator${ops:-} 2>&1 | artifact_out
        # sometimes the state will change among Error, Running, and CrashLoopBackOff for a
        # few seconds before finally settling down in Error or CrashLoopBackOff
        os::cmd::try_until_text "oc get pods -l component=curator${ops:-} -o jsonpath='{.items[0].status.containerStatuses[?(@.name==\"curator\")].state.waiting.reason}'" "Error|CrashLoopBackOff"
        os::cmd::try_until_success "oc get pods -l component=curator${ops:-} -o jsonpath='{.items[0].metadata.name}' > /dev/null 2>&1"
        curpod=$( oc get pods -l component=curator${ops:-} -o jsonpath='{.items[0].metadata.name}' )
    else
        # wait until redeployed
        oc rollout status -w dc/logging-curator${ops:-} 2>&1 | artifact_out
        oc scale --replicas=1 dc/logging-curator${ops:-} 2>&1 | artifact_out
        if os::cmd::try_until_text "oc get pods -l component=curator${ops:-} -o jsonpath='{.items[0].status.containerStatuses[?(@.name==\"curator\")].ready}'" "true" ; then
            artifact_log curator was started
        else
            oc get pods -l component=curator${ops:-} -o jsonpath='{.items[0].status.containerStatuses[?(@.name=="curator")].ready}'
            oc get pods
            oc get dc
            oc get dc/logging-curator
            exit 1
        fi
        curpod=$( get_running_pod curator${ops:-} )
    fi
}

cleanup_failed_deployments() {
    oc rollout cancel dc/logging-curator${ops:-} 2>&1 | artifact_out || :
    for pod in $( oc get pods | awk '/^logging-curator-.*-deploy.*Error/ {print $1}' ) ; do
        if [ -n "${pod:-}" ] ; then
            oc delete pod --force $pod 2>&1 | artifact_out
        fi
    done
}

uses_config_maps() {
    test -n "$( oc get dc logging-curator -o jsonpath='{.spec.template.spec.volumes[*].configMap.name}' )"
}

update_config_and_restart() {
    # $1 - file holding configuration
    # $2 - if present, expect errors
    if uses_config_maps ; then
        # use configmap
        oc delete configmap logging-curator 2>&1 | artifact_out || :
        sleep 1
        if grep -q ^apiVersion: $1 ; then
            oc create -f $1 2>&1 | artifact_out || : # oc get yaml dump, not a curator config file
        else
            oc create configmap logging-curator --from-file=config.yaml=$1 2>&1 | artifact_out
        fi
        sleep 1
    else
        # use secret volume mount
        oc delete secret curator-config${ops:-} 2>&1 | artifact_out || artifact_log no such secret curator-config${ops:-} - ignore
        oc secrets new curator-config${ops:-} settings=$1 2>&1 | artifact_out
        oc volumes dc/logging-curator${ops:-} --add --type=secret --secret-name=curator-config${ops:-} \
            --mount-path=/etc/curator --name=curator-config --overwrite 2>&1 | artifact_out
    fi
    restart_curator ${2:-}
}

if uses_config_maps ; then
    origconfig=$( mktemp )
    oc get configmap logging-curator -o yaml > $origconfig
fi

cleanup() {
    local return_code="$?"
    set +e
    if [ $return_code = 0 ] ; then
        mycmd=os::log::info
    else
        mycmd=os::log::error
    fi
    $mycmd curator test finished at $( date )
    # dump the pods before we restart them
    if [ -n "${curpod:-}" ] ; then
        oc logs $curpod > $ARTIFACT_DIR/curator-$curpod.log 2>&1
    fi
    # delete indices
    artifact_log espod $espod esopspod $esopspod
    delete_indices $essvc
    if [ -n "${esopspod:-}" ] ; then
        delete_indices $esopssvc
    fi
    if [ -n "${origconfig:-}" -a -f $origconfig ] ; then
        oc replace --force -f $origconfig 2>&1 | artifact_out
        sleep 1
        rm -f $origconfig
    else
        oc delete secret curator-config 2>&1 | artifact_out
        oc delete secret curator-config-ops 2>&1 | artifact_out
        oc set volumes dc/logging-curator --remove --name=curator-config 2>&1 | artifact_out
        if [ -n "${esopspod:-}" ] ; then
            oc set volumes dc/logging-curator-ops --remove --name=curator-config 2>&1 | artifact_out
        fi
    fi
    oc set env dc/logging-curator CURATOR_SCRIPT_LOG_LEVEL=INFO CURATOR_LOG_LEVEL=ERROR 2>&1 | artifact_out
    if [ -n "${esopspod:-}" ] ; then
        oc set env dc/logging-curator-ops CURATOR_SCRIPT_LOG_LEVEL=INFO CURATOR_LOG_LEVEL=ERROR 2>&1 | artifact_out
    fi
    restart_curator
    if [ -n "${esopssvc:-}" ] ; then
        ops="-ops" restart_curator
    fi
    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
    exit $return_code
}
trap "cleanup" EXIT

os::log::info Starting curator test at $( date )

espod=$( get_es_pod es )
esopspod=$( get_es_pod es-ops )
essvc=$( get_es_svc es )
esopssvc=$( get_es_svc es-ops )
curpod=$( get_running_pod curator )
stop_curator $curpod
oc set env dc/logging-curator CURATOR_SCRIPT_LOG_LEVEL=DEBUG CURATOR_LOG_LEVEL=DEBUG 2>&1 | artifact_out
restart_curator
if [ -n "${esopspod:-}" ] ; then
    curopspod=$( get_running_pod curator-ops )
    ops="-ops" stop_curator $curopspod
    oc set env dc/logging-curator-ops CURATOR_SCRIPT_LOG_LEVEL=DEBUG CURATOR_LOG_LEVEL=DEBUG 2>&1 | artifact_out
    ops="-ops" restart_curator
    curpod=$( get_running_pod curator )
fi
fpod=$( oc get pods --selector component=fluentd  -o jsonpath='{ .items[*].metadata.name }' | head -1 )
tf='%Y.%m.%d'
today=`date -u +"$tf"`
yesterday=`date -u +"$tf" --date=yesterday`
lastweek=`date -u +"$tf" --date="last week"`
fourweeksago=`date -u +"$tf" --date="4 weeks ago"`
thirtyonedaysago=`date -u +"$tf" --date="31 days ago"`
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
    curpod=$( get_running_pod curator )
    curtest=`mktemp --suffix=.yaml`
    cat > $curtest <<EOF
this-project-name-is-far-far-too-long-this-project-name-is-far-far-too-long-this-project-name-is-far-far-too-long-this-project-name-is-far-far-too-long:
  delete:
    days: 1
EOF
    os::log::info Testing curator for incorrect project name length error - updating config and rolling out . . .
    stop_curator $curpod
    update_config_and_restart $curtest errors
    # curator pod status reported an error state
    os::cmd::try_until_text "oc logs $curpod 2>&1" "The project name length must be less than or equal to"
    cleanup_failed_deployments
    stop_curator $curpod
    cat > $curtest <<EOF
-BOGUS^PROJECT^NAME:
  delete:
    days: 1
EOF
    os::log::info Testing curator for improper project name error - updating config and rolling out . . .
    update_config_and_restart $curtest errors
    # curator pod status reported an error state
    os::cmd::try_until_text "oc logs $curpod 2>&1" "The project name must match this regex"
    cleanup_failed_deployments
    stop_curator $curpod
    update_config_and_restart $origconfig
}

basictest() {
    local essvc=$1
    ops=${2:-""}
    create_indices $essvc

    sleeptime=${CURATOR_WAIT_SECS:-120} # seconds
    # get current curator pod
    curpod=$( get_running_pod curator${ops} )
    # show current indices, 1st deletion is triggered by restart curator pod; 2nd deletion is triggered by runhour and runminute
    artifact_log current indices before 1st deletion are:
    oc exec $curpod -- curator --host logging-es${ops} --use_ssl --certificate /etc/curator/keys/ca \
       --client-cert /etc/curator/keys/cert --client-key /etc/curator/keys/key --loglevel ERROR \
       show indices --all-indices 2>&1 | artifact_out
    # add the curator config yaml settings file
    curtest=$( mktemp --suffix=.yaml )
    # see what the current time and timezone are in the curator pod
    oc exec $curpod -- date 2>&1 | artifact_out
    # calculate the runhour and runminute to run 5 minutes from now
    tz=`timedatectl | awk '/Time zone:/ {print $3}'`
    runhour=`TZ=$tz date +%H --date="TZ=\"$tz\" $sleeptime seconds hence"`
    runminute=`TZ=$tz date +%M --date="TZ=\"$tz\" $sleeptime seconds hence"`
    runtime=`TZ=$tz date +%s --date="TZ=\"$tz\" $sleeptime seconds hence"`
    cat > $curtest <<EOF
.defaults:
  delete:
    days: 31
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
    stop_curator $curpod
    update_config_and_restart $curtest
    # wait for curator run 1 to finish
    os::cmd::try_until_text "oc logs $curpod 2>&1 | grep -c 'curator run finish'" 1 $(( 2 * minute ))
    # show current indices
    artifact_log current indices after 1st deletion are:
    oc exec $curpod -- curator --host logging-es${ops} --use_ssl --certificate /etc/curator/keys/ca \
       --client-cert /etc/curator/keys/cert --client-key /etc/curator/keys/key --loglevel ERROR \
       show indices --all-indices 2>&1 | artifact_out
    os::cmd::expect_success "verify_indices $curpod $ops"

    # now, add back the same messages/indices and see if runhour and runminute are working
    create_indices $essvc
    # show current indices
    artifact_log current indices before 2nd deletion are:
    oc exec $curpod -- curator --host logging-es${ops} --use_ssl --certificate /etc/curator/keys/ca \
       --client-cert /etc/curator/keys/cert --client-key /etc/curator/keys/key --loglevel ERROR \
       show indices --all-indices 2>&1 | artifact_out

    current_time="$( TZ=$tz date +%s )"
    remaining_time="$(( runtime - current_time ))"
    # wait for curator run 2 to finish
    os::cmd::try_until_text "oc logs $curpod 2>&1 | grep -c 'curator run finish'" 2 $(( $remaining_time * second ))
    os::log::info verify indices deletion after curator run time
    # show current indices
    artifact_log current indices after 2nd deletion are:
    oc exec $curpod -- curator --host logging-es${ops} --use_ssl --certificate /etc/curator/keys/ca \
       --client-cert /etc/curator/keys/cert --client-key /etc/curator/keys/key --loglevel ERROR \
       show indices --all-indices 2>&1 | artifact_out
    os::cmd::expect_success "verify_indices $curpod $ops"

    return 0
}

regextest() {
    local essvc=$1
    ops=${2:-""}
    create_indices $essvc

    sleeptime=${CURATOR_WAIT_SECS:-120} # seconds
    # get current curator pod
    curpod=$( get_running_pod curator${ops} )
    # show current indices, 1st deletion is triggered by restart curator pod; 2nd deletion is triggered by runhour and runminute
    artifact_log current indices before 1st deletion are:
    oc exec $curpod -- curator --host logging-es${ops} --use_ssl --certificate /etc/curator/keys/ca \
       --client-cert /etc/curator/keys/cert --client-key /etc/curator/keys/key --loglevel ERROR \
       show indices --all-indices 2>&1 | artifact_out
    # add the curator config yaml settings file
    curtest=$( mktemp --suffix=.yaml )
    # see what the current time and timezone are in the curator pod
    oc exec $curpod -- date 2>&1 | artifact_out
    # calculate the runhour and runminute to run 5 minutes from now
    tz=`timedatectl | awk '/Time zone:/ {print $3}'`
    runhour=`TZ=$tz date +%H --date="TZ=\"$tz\" $sleeptime seconds hence"`
    runminute=`TZ=$tz date +%M --date="TZ=\"$tz\" $sleeptime seconds hence"`
    runtime=`TZ=$tz date +%s --date="TZ=\"$tz\" $sleeptime seconds hence"`
    cat > $curtest <<EOF
.defaults:
  delete:
    days: 31
  runhour: $runhour
  runminute: $runminute
  timezone: $tz
project-dev:
  delete:
    days: 1
project-prod:
  delete:
    weeks: 4
.operations:
  delete:
    months: 2
.regex:
  - pattern: '^project\..+\-qe\..*$'
    delete:
      days: 7
EOF
    stop_curator $curpod
    update_config_and_restart $curtest
    # wait for curator run 1 to finish
    os::cmd::try_until_text "oc logs $curpod 2>&1 | grep -c 'curator run finish'" 1 $(( 2 * minute ))
    # show current indices
    artifact_log current indices after 1st deletion are:
    oc exec $curpod -- curator --host logging-es${ops} --use_ssl --certificate /etc/curator/keys/ca \
       --client-cert /etc/curator/keys/cert --client-key /etc/curator/keys/key --loglevel ERROR \
       show indices --all-indices 2>&1 | artifact_out
    os::cmd::expect_success "verify_indices $curpod $ops"

    # now, add back the same messages/indices and see if runhour and runminute are working
    create_indices $essvc
    # show current indices
    artifact_log current indices before 2nd deletion are:
    oc exec $curpod -- curator --host logging-es${ops} --use_ssl --certificate /etc/curator/keys/ca \
       --client-cert /etc/curator/keys/cert --client-key /etc/curator/keys/key --loglevel ERROR \
       show indices --all-indices 2>&1 | artifact_out

    current_time="$( TZ=$tz date +%s )"
    remaining_time="$(( runtime - current_time ))"
    # wait for curator run 2 to finish
    os::cmd::try_until_text "oc logs $curpod 2>&1 | grep -c 'curator run finish'" 2 $(( $remaining_time * second ))
    os::log::info verify indices deletion after curator run time
    # show current indices
    artifact_log current indices after 2nd deletion are:
    oc exec $curpod -- curator --host logging-es${ops} --use_ssl --certificate /etc/curator/keys/ca \
       --client-cert /etc/curator/keys/cert --client-key /etc/curator/keys/key --loglevel ERROR \
       show indices --all-indices 2>&1 | artifact_out
    os::cmd::expect_success "verify_indices $curpod $ops"

    return 0
}

test_project_name_errors

# test without ops cluster first
basictest $essvc

if [ -n "$esopssvc" ]; then
    basictest $esopssvc "-ops"
fi

regextest $essvc

if [ -n "$esopssvc" ]; then
    regextest $esopssvc "-ops"
fi
