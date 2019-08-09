#!/bin/bash

# This is a test suite for the docker log driver
# json-file and/or journald multiline logs

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::test::junit::declare_suite_start "test/docker_multiline"

FLUENTD_WAIT_TIME=${FLUENTD_WAIT_TIME:-$(( 2 * minute ))}

stop_fluentd() {
  artifact_log at this point there should be 1 fluentd running in Running state
  oc get pods 2>&1 | artifact_out
  local fpod=$( get_running_pod fluentd )
  oc label node --all logging-infra-fluentd- 2>&1 | artifact_out
  os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME
  artifact_log at this point there should be no fluentd running - number ready is 0
  oc get pods 2>&1 | artifact_out
  # for some reason, in this test, after .status.numberReady is 0, the fluentd pod hangs around
  # in the Terminating state for many seconds, which seems to cause problems with subsequent tests
  # so, we have to wait for the pod to completely disappear - we cannot rely on .status.numberReady == 0
  if [ -n "${fpod:-}" ] ; then
    os::cmd::try_until_failure "oc get pod $fpod > /dev/null 2>&1" $FLUENTD_WAIT_TIME
  fi
}

start_fluentd() {
  sudo rm -f /var/log/fluentd/fluentd.log
  oc label node --all logging-infra-fluentd=true 2>&1 | artifact_out
  os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running " $FLUENTD_WAIT_TIME
}

cleanup() {
    local return_code="$?"
    set +e

    if [ $return_code = 0 ] ; then
        mycmd=os::log::info
    else
        mycmd=os::log::error
    fi
    $mycmd docker_multiline test finished at $( date )

    if [ -n "${proj:-}" ] ; then
        oc delete project $proj 2>&1 | artifact_out
        os::cmd::try_until_failure "oc get project $proj -o yaml > /dev/null 2>&1" 2>&1 | artifact_out
        curl_es $essvc "/project.${proj}.*" -XDELETE 2>&1 | artifact_out
    fi
    fpod=$( get_running_pod fluentd )
    if [ -n "${fpod:-}" ] ; then
        get_fluentd_pod_log > $ARTIFACT_DIR/docker-multiline-fluentd-pod.log
    fi
    if [ "${orig_MERGE_JSON_LOG:-}" = unset ] ; then
        orig_MERGE_JSON_LOG="MERGE_JSON_LOG-"
    fi
    if [ "${orig_CDM_UNDEFINED_TO_STRING:-}" = unset ] ; then
        orig_CDM_UNDEFINED_TO_STRING="CDM_UNDEFINED_TO_STRING-"
    fi
    if [ "${orig_USE_MULTILINE_JSON:-}" = unset ] ; then
        orig_USE_MULTILINE_JSON="USE_MULTILINE_JSON-"
    fi
    if [ "${orig_USE_MULTILINE_JOURNAL:-}" = unset ] ; then
        orig_USE_MULTILINE_JOURNAL="USE_MULTILINE_JOURNAL-"
    fi
    if [ -n "${orig_MERGE_JSON_LOG:-}" -o -n "${orig_CDM_UNDEFINED_TO_STRING:-}" -o -n "${orig_USE_MULTILINE_JSON:-}" -o -n "${orig_USE_MULTILINE_JOURNAL:-}" ] ; then
        stop_fluentd
        oc set env daemonset/logging-fluentd ${orig_USE_MULTILINE_JSON:-} ${orig_USE_MULTILINE_JOURNAL:-} ${orig_MERGE_JSON_LOG:-} ${orig_CDM_UNDEFINED_TO_STRING:-} 2>&1 | artifact_out
        start_fluentd
    fi

    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
    exit $return_code
}
trap "cleanup" EXIT

# operations index can be in a separate cluster
essvc=$( get_es_svc es )

# create a test project
proj=test-docker-multiline
oc adm new-project $proj --node-selector='' 2>&1 | artifact_out
os::cmd::try_until_success "oc get project $proj -o yaml > /dev/null 2>&1" 2>&1 | artifact_out

# turn on MERGE_JSON_LOG if not already
# enable merge json log
orig_MERGE_JSON_LOG=$( oc set env daemonset/logging-fluentd --list | grep \^MERGE_JSON_LOG= ) || :
if [ -z "$orig_MERGE_JSON_LOG" ] ; then
    orig_MERGE_JSON_LOG=unset
fi
orig_CDM_UNDEFINED_TO_STRING=$( oc set env daemonset/logging-fluentd --list | grep \^CDM_UNDEFINED_TO_STRING= ) || :
if [ -z "$orig_CDM_UNDEFINED_TO_STRING" ] ; then
    orig_CDM_UNDEFINED_TO_STRING=unset
fi
orig_USE_MULTILINE_JSON=$( oc set env daemonset/logging-fluentd --list | grep \^USE_MULTILINE_JSON= ) || :
if [ -z "$orig_USE_MULTILINE_JSON" ] ; then
    orig_USE_MULTILINE_JSON=unset
fi
orig_USE_MULTILINE_JOURNAL=$( oc set env daemonset/logging-fluentd --list | grep \^USE_MULTILINE_JOURNAL= ) || :
if [ -z "$orig_USE_MULTILINE_JOURNAL" ] ; then
    orig_USE_MULTILINE_JOURNAL=unset
fi
stop_fluentd
oc set env daemonset/logging-fluentd USE_MULTILINE_JSON=true USE_MULTILINE_JOURNAL=true MERGE_JSON_LOG=true CDM_UNDEFINED_TO_STRING=false 2>&1 | artifact_out
start_fluentd

# create a test pod to generate very long lines
ident=$( openssl rand -hex 16 )
rm -f $ARTIFACT_DIR/test-message
for ii in $( seq 1 1638 ) ; do
    printf "0123456789" >> $ARTIFACT_DIR/test-message
done
echo "" >> $ARTIFACT_DIR/test-message
expected=10
pod=$proj
oc process -f $OS_O_A_L_DIR/hack/testing/templates/test-template.yaml \
    -p TEST_NAMESPACE_NAME=$proj -p TEST_POD_NAME=$pod -p UNIQUEID=$ident \
    -p TEST_POD_SLEEP_TIME=600 -p TEST_ITERATIONS=$expected -p FORMAT=json \
    -p TEST_POD_MESSAGE=$( cat $ARTIFACT_DIR/test-message ) > $ARTIFACT_DIR/test-pod.yaml
oc create -f $ARTIFACT_DIR/test-pod.yaml 2>&1 | artifact_out
os::cmd::try_until_success "oc -n $proj get pod $pod -o yaml > /dev/null 2>&1" 2>&1 | artifact_out

# wait until es msg count is 10
rc=0
qs='{"query":{"term":{"uniqueid":"'"${ident}"'"}}}'
if os::cmd::try_until_text "curl_es ${essvc} /project.${proj}.*/_count -X POST -d '$qs' | get_count_from_json" "^${expected}\$" $(( 120 * second )); then
    # verify messages
    curl_es ${essvc} "/project.${proj}.*/_search" -X POST -d "$qs" > $ARTIFACT_DIR/records.json 2>&1 || :
    for ii in $( seq 0 $(( expected - 1 )) ) ; do
        cat $ARTIFACT_DIR/records.json | jq -r .hits.hits[$ii]._source.message > $ARTIFACT_DIR/message.$ii
        if ! diff -q $ARTIFACT_DIR/test-message $ARTIFACT_DIR/message.$ii ; then
            os::log::error "test message does not match $ARTIFACT_DIR/message.$ii"
            rc=1
            break
        fi
    done
else
    rc=1
    os::log::error "Could not find test records"
    curl_es ${essvc} "/project.${proj}.*/_search" -X POST -d "$qs" > $ARTIFACT_DIR/err_raw_search_output.txt 2>&1 || :
    cat $ARTIFACT_DIR/err_raw_search_output.txt | jq . > $ARTIFACT_DIR/err_search_output.json 2>&1 || :
    curl_es ${essvc} /_cat/indices?v 2>&1 | artifact_out
fi
oc -n $proj delete --force pod $pod 2>&1 | artifact_out

exit $rc
