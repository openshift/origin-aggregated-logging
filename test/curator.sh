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

if [ -n "${DEBUG:-}" ] ; then
    set -x
    curl_output() {
        python -mjson.tool
    }
else
    curl_output() {
        cat > /dev/null 2>&1
    }
fi

add_message_to_index() {
    local index="$1"
    local message="${2:-'curatortest mesage'}"
    local espod="$3"
    curl_es "$espod" "/$index/curatortest/" -XPOST -d '{
    "message" : "'${message}${3}'"
}' | curl_output
}

delete_indices() {
    local espod="$1"
    curl_es $espod "/*.curatortest.*" -XDELETE | curl_output
}

skip_list=("^\." "^default")

create_indices() {
    local espod=$1
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
        add_message_to_index "${this_proj}.curatortest.$1" "$this_proj $1 message" $espod
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
                os::log::debug good - index $this_idx is present
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
                os::log::debug good - index $this_idx is missing
            fi
        fi
        shift
    done
    if [ $rc -ne 0 ] ; then
        os::log::error "The index list is:"
        cat $curout
    fi
    rm -f $curout
    return $rc
}

restart_curator() {
    # $1 - if present, expect errors
    # redeploy dc
    # if there is a deployment already in progress, do not redeploy
    if oc rollout status --watch=false dc/logging-curator${ops:-} 2>&1 | grep -q "Waiting for rollout to finish" ; then
        : # already in progress
    else
        os::log::debug "$( oc rollout latest dc/logging-curator${ops:-} )"
    fi
    # wait until redeployed
    os::log::debug "$( oc rollout status -w dc/logging-curator${ops:-} )"
    if [ -n "${1:-}" ] ; then
        # sometimes the state will change among Error, Running, and CrashLoopBackOff for a
        # few seconds before finally settling down in Error or CrashLoopBackOff
        os::cmd::try_until_text "oc get pods -l component=curator${ops:-} -o jsonpath='{.items[0].status.containerStatuses[?(@.name==\"curator\")].state.waiting.reason}'" "Error|CrashLoopBackOff"
    else
        os::cmd::try_until_text "oc get pods -l component=curator${ops:-} -o jsonpath='{.items[0].status.containerStatuses[?(@.name==\"curator\")].ready}'" "true"
        curpod=`get_running_pod curator${ops:-}`
    fi
}

uses_config_maps() {
    test -n "$( oc get dc logging-curator -o jsonpath='{.spec.template.spec.volumes[*].configMap.name}' )"
}

update_config_and_restart() {
    # $1 - file holding configuration
    # $2 - if present, expect errors
    if uses_config_maps ; then
        # use configmap
        os::log::debug "$( oc delete configmap logging-curator )" || :
        sleep 1
        if grep -q ^apiVersion: $1 ; then
            os::log::debug "$( oc create -f $1 )" || : # oc get yaml dump, not a curator config file
        else
            os::log::debug "$( oc create configmap logging-curator --from-file=config.yaml=$1 )"
        fi
        sleep 1
    else
        # use secret volume mount
        os::log::debug "$( oc delete secret curator-config${ops:-} )" || os::log::debug "no such secret curator-config${ops:-} - ignore"
        os::log::debug "$( oc secrets new curator-config${ops:-} settings=$1 )"
        os::log::debug "$( oc volumes dc/logging-curator${ops:-} --add --type=secret --secret-name=curator-config${ops:-} --mount-path=/etc/curator --name=curator-config --overwrite )"
    fi
    restart_curator ${2:-}
}

if uses_config_maps ; then
    origconfig=`mktemp`
    os::log::debug "$( oc get configmap logging-curator -o yaml > $origconfig )" || :
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
        oc logs $curpod > $ARTIFACT_DIR/$curpod.log 2>&1
    fi
    # delete indices
    delete_indices $espod
    if [ -n "${esopspod:-}" ] ; then
        delete_indices $esopspod
    fi
    if [ -n "${origconfig:-}" -a -f $origconfig ] ; then
        os::log::debug "$( oc replace --force -f $origconfig )"
        sleep 1
        rm -f $origconfig
    else
        os::log::debug "$( oc delete secret curator-config )"
        os::log::debug "$( oc delete secret curator-config-ops )"
        os::log::debug "$( oc set volumes dc/logging-curator --remove --name=curator-config )"
        if [ -n "${esopspod:-}" ] ; then
            os::log::debug "$( oc set volumes dc/logging-curator-ops --remove --name=curator-config )"
        fi
    fi
    os::log::debug "$( oc set env dc/logging-curator CURATOR_SCRIPT_LOG_LEVEL=INFO CURATOR_LOG_LEVEL=ERROR )"
    if [ -n "${esopspod:-}" ] ; then
        os::log::debug "$( oc set env dc/logging-curator-ops CURATOR_SCRIPT_LOG_LEVEL=INFO CURATOR_LOG_LEVEL=ERROR )"
    fi
    restart_curator
    if [ -n "${esopspod:-}" ] ; then
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

os::log::debug "$( oc set env dc/logging-curator CURATOR_SCRIPT_LOG_LEVEL=DEBUG CURATOR_LOG_LEVEL=DEBUG )"
os::log::info Enabled debug for dc/logging-curator - rolling out . . .
# the set env may trigger a rollout - if so, wait for it to complete
os::log::debug "$( oc rollout status -w dc/logging-curator )"
os::log::info Rolled out dc/logging-curator
if [ -n "${esopspod:-}" ] ; then
    os::log::debug "$( oc set env dc/logging-curator-ops CURATOR_SCRIPT_LOG_LEVEL=DEBUG CURATOR_LOG_LEVEL=DEBUG )"
    os::log::info Enabled debug for dc/logging-curator-ops - rolling out . . .
    os::log::debug "$( oc rollout status -w dc/logging-curator-ops )"
    os::log::info Rolled out dc/logging-curator-ops
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
    curpod=`get_running_pod curator`
    curtest=`mktemp --suffix=.yaml`
    cat > $curtest <<EOF
this-project-name-is-far-far-too-long-this-project-name-is-far-far-too-long-this-project-name-is-far-far-too-long-this-project-name-is-far-far-too-long:
  delete:
    days: 1
EOF
    os::log::info Testing curator for incorrect project name length error - updating config and rolling out . . .
    update_config_and_restart $curtest errors
    # curator pod status reported an error state
    curpod=$( oc get pods -l component=curator -o jsonpath='{.items[0].metadata.name}' )
    os::cmd::expect_success_and_text "oc logs $curpod 2>&1" "The project name length must be less than or equal to"
    cat > $curtest <<EOF
-BOGUS^PROJECT^NAME:
  delete:
    days: 1
EOF
    os::log::info Testing curator for improper project name error - updating config and rolling out . . .
    update_config_and_restart $curtest errors
    # curator pod status reported an error state
    curpod=$( oc get pods -l component=curator -o jsonpath='{.items[0].metadata.name}' )
    os::cmd::expect_success_and_text "oc logs $curpod 2>&1" "The project name must match this regex"
    update_config_and_restart $origconfig
}

basictest() {
    local espod=$1
    ops=${2:-""}
    create_indices $espod

    sleeptime=${CURATOR_WAIT_SECS:-300} # seconds
    # get current curator pod
    curpod=`get_running_pod curator${ops}`
    # show current indices, 1st deletion is triggered by restart curator pod; 2nd deletion is triggered by runhour and runminute
    os::log::debug current indices before 1st deletion are:
    os::log::debug "$( oc exec $curpod -- curator --host logging-es${ops} --use_ssl --certificate /etc/curator/keys/ca \
       --client-cert /etc/curator/keys/cert --client-key /etc/curator/keys/key --loglevel ERROR \
       show indices --all-indices )"
    # add the curator config yaml settings file
    curtest=`mktemp --suffix=.yaml`
    # see what the current time and timezone are in the curator pod
    os::log::debug "$( oc exec $curpod -- date )"
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
    update_config_and_restart $curtest
    # wait for curator run 1 to finish
    os::cmd::try_until_text "oc logs $curpod 2>&1 | grep -c 'curator run finish'" 1 $(( 2 * minute ))
    # show current indices
    os::log::debug current indices after 1st deletion are:
    os::log::debug "$( oc exec $curpod -- curator --host logging-es${ops} --use_ssl --certificate /etc/curator/keys/ca \
       --client-cert /etc/curator/keys/cert --client-key /etc/curator/keys/key --loglevel ERROR \
       show indices --all-indices )"
    os::cmd::expect_success "verify_indices $curpod $ops"

    # now, add back the same messages/indices and see if runhour and runminute are working
    create_indices $espod
    # show current indices
    os::log::debug current indices before 2nd deletion are:
    os::log::debug "$( oc exec $curpod -- curator --host logging-es${ops} --use_ssl --certificate /etc/curator/keys/ca \
       --client-cert /etc/curator/keys/cert --client-key /etc/curator/keys/key --loglevel ERROR \
       show indices --all-indices )"

    current_time="$( TZ=$tz date +%s )"
    remaining_time="$(( runtime - current_time ))"
    os::log::info sleeping $remaining_time seconds to see if runhour and runminute are working . . .
    sleep $remaining_time
    # wait for curator run 2 to finish
    os::cmd::try_until_text "oc logs $curpod 2>&1 | grep -c 'curator run finish'" 2 $(( 2 * minute ))
    os::log::info verify indices deletion after curator run time
    # show current indices
    os::log::debug current indices after 2nd deletion are:
    os::log::debug "$( oc exec $curpod -- curator --host logging-es${ops} --use_ssl --certificate /etc/curator/keys/ca \
       --client-cert /etc/curator/keys/cert --client-key /etc/curator/keys/key --loglevel ERROR \
       show indices --all-indices )"
    os::cmd::expect_success "verify_indices $curpod $ops"

    return 0
}

test_project_name_errors

# test without ops cluster first
basictest $espod

if [ -n "$esopspod" ]; then
    basictest $esopspod "-ops"
fi
