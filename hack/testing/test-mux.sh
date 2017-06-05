#! /bin/bash

# test the mux route and service
# - can accept secure_forward from a "client" fluentd

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

if [ "$USE_MUX_CLIENT" == "false" -o "$MUX_ALLOW_EXTERNAL" == "false" ]; then
    echo "Skipping -- This test requires both USE_MUX_CLIENT and MUX_ALLOW_EXTERNAL are true."
    exit 0
fi

ARTIFACT_DIR=${ARTIFACT_DIR:-${TMPDIR:-/tmp}/origin-aggregated-logging}
if [ ! -d $ARTIFACT_DIR ] ; then
    mkdir -p $ARTIFACT_DIR
fi

if oc get project testproj > /dev/null 2>&1 ; then
    echo using existing project testproj
else
    oadm new-project testproj --node-selector='' > /dev/null
fi

print_message() {
    if [ "${VERBOSE:-false}" = true ] ; then
        query_es_from_es $espod $myproject _search $myfield $mymessage >> $MUXDEBUG

        local es_pod=`get_running_pod es`
        local es_ops_pod=`get_running_pod es-ops`
        oc exec $es_pod -- curl --connect-timeout 1 -s -k \
           --cert /etc/elasticsearch/secret/admin-cert --key /etc/elasticsearch/secret/admin-key \
           'https://localhost:9200/_cat/indices?v' >> $MUXDEBUG
        oc exec $es_ops_pod -- curl --connect-timeout 1 -s -k \
           --cert /etc/elasticsearch/secret/admin-cert --key /etc/elasticsearch/secret/admin-key \
           'https://localhost:9200/_cat/indices?v' >> $MUXDEBUG
    fi
}

cleanup_forward() {

  # undeploy fluentd
  oc label node --all logging-infra-fluentd-

  wait_for_pod_ACTION stop $fpod

  # Revert configmap if we haven't yet
  oc get configmap/logging-fluentd -o yaml | \
      sed -e '/@include configs.d\/user\/filter-pre-mux-test-client.conf/ d' | oc replace -f -

  oc patch configmap/logging-fluentd --type=json --patch '[{ "op": "replace", "path": "/data/filter-pre-mux-test-client.conf", "value": "# conf file for mux test" }]'

  # redeploy fluentd
  oc label node --all logging-infra-fluentd=true

  # wait for fluentd to start
  wait_for_pod_ACTION start fluentd

  fpod=`get_running_pod fluentd`
}

reset_fluentd_daemonset() {
  oc set env daemonset/logging-fluentd USE_MUX_CLIENT=true

  muxcerts=`oc get daemonset logging-fluentd -o yaml | egrep muxcerts` || :

  if [ "$muxcerts" = "" ]; then
    oc get daemonset logging-fluentd -o yaml | sed '/volumes:/ a\
      - name: muxcerts\
        secret:\
          defaultMode: 420\
          secretName: logging-mux\
' | oc replace -f -

    oc get daemonset logging-fluentd -o yaml | sed '/volumeMounts:/ a\
        - mountPath: /etc/fluent/muxkeys\
          name: muxcerts\
          readOnly: true\
' | oc replace -f -
  fi
}

# OPTIONS:
SET_CONTAINER_VALS=1
NO_CONTAINER_VALS=2
MISMATCH_NAMESPACE_TAG=3
NO_PROJECT_TAG=4
update_current_fluentd() {
  # this will update it so the current fluentd does not send logs to an ES host
  # but instead forwards to the forwarding fluentd
  myoption=${1:-0}

  # make sure we are in logging
  oc project logging

  # undeploy fluentd
  oc label node --all logging-infra-fluentd-

  wait_for_pod_ACTION stop $fpod

  # edit so we don't filter or send to ES
  oc get configmap/logging-fluentd -o yaml | sed '/## filters/ a\
      @include configs.d/user/filter-pre-mux-test-client.conf' | oc replace -f -

  # update configmap filter-pre-mux-test-client.conf
  if [ $myoption -eq $NO_CONTAINER_VALS ]; then
      oc patch configmap/logging-fluentd --type=json --patch '[{ "op": "replace", "path": "/data/filter-pre-mux-test-client.conf", "value": "\
      <match journal>\n\
        @type rewrite_tag_filter\n\
        rewriterule1 MESSAGE .+ project.testproj.mux\n\
        rewriterule2 message .+ project.testproj.mux\n\
      </match>\n\
      <filter project.testproj.mux>\n\
        @type record_transformer\n\
        enable_ruby\n\
        <record>\n\
        @timestamp ${time.strftime(\"%Y-%m-%dT%H:%M:%S%z\")}\n\
        </record>\n\
      </filter>"}]'
  elif [ $myoption -eq $SET_CONTAINER_VALS ]; then
      oc patch configmap/logging-fluentd --type=json --patch '[{ "op": "replace", "path": "/data/filter-pre-mux-test-client.conf", "value": "\
      <match journal>\n\
        @type rewrite_tag_filter\n\
        rewriterule1 MESSAGE .+ project.testproj.mux\n\
        rewriterule2 message .+ project.testproj.mux\n\
      </match>\n\
      <filter project.testproj.mux>\n\
        @type record_transformer\n\
        enable_ruby\n\
        <record>\n\
        @timestamp ${time.strftime(\"%Y-%m-%dT%H:%M:%S%z\")}\n\
        CONTAINER_NAME k8s_mux.01234567_logging-mux_testproj_00000000-1111-2222-3333-444444444444_55555555\n\
        CONTAINER_ID_FULL 0123456789012345678901234567890123456789012345678901234567890123\n\
        </record>\n\
      </filter>"}]'
  elif [ $myoption -eq $MISMATCH_NAMESPACE_TAG ]; then
      oc patch configmap/logging-fluentd --type=json --patch '[{ "op": "replace", "path": "/data/filter-pre-mux-test-client.conf", "value": "\
      <match journal>\n\
        @type rewrite_tag_filter\n\
        rewriterule1 MESSAGE .+ project.bogus.mux\n\
        rewriterule2 message .+ project.bogus.mux\n\
      </match>\n\
      <filter project.bogus.mux>\n\
        @type record_transformer\n\
        enable_ruby\n\
        <record>\n\
        @timestamp ${time.strftime(\"%Y-%m-%dT%H:%M:%S%z\")}\n\
        CONTAINER_NAME k8s_mux.01234567_logging-mux_testproj_00000000-1111-2222-3333-444444444444_55555555\n\
        CONTAINER_ID_FULL 0123456789012345678901234567890123456789012345678901234567890123\n\
        </record>\n\
      </filter>"}]'
  else
      oc patch configmap/logging-fluentd --type=json --patch '[{ "op": "replace", "path": "/data/filter-pre-mux-test-client.conf", "value": "\
      <match journal>\n\
        @type rewrite_tag_filter\n\
        rewriterule1 MESSAGE .+ test.bogus.mux\n\
        rewriterule2 message .+ test.bogus.mux\n\
      </match>\n\
      <filter test.bogus.mux>\n\
        @type record_transformer\n\
        enable_ruby\n\
        <record>\n\
        @timestamp ${time.strftime(\"%Y-%m-%dT%H:%M:%S%z\")}\n\
        </record>\n\
      </filter>"}]'
  fi

  reset_fluentd_daemonset

  # redeploy fluentd
  oc label node --all logging-infra-fluentd=true

  # wait for fluentd to start
  wait_for_pod_ACTION start fluentd

  fpod=`get_running_pod fluentd`
}

write_and_verify_logs() {
    # expected number of matches
    expected=$1
    is_testproj=$2
    no_container_vals=$3
    mismatch_namespace=${4:-0}
    no_project_tag=${5:-0}

    local es_pod=`get_running_pod es`
    local es_ops_pod=`get_running_pod es-ops`
    if [ -z "$es_ops_pod" ] ; then
        es_ops_pod=$es_pod
    fi
    local uuid_es=`uuidgen`
    local uuid_es_ops=`uuidgen`

    add_test_message $uuid_es
    logger -i -p local6.info -t $uuid_es_ops $uuid_es_ops

    local rc=0

    if [ "${VERBOSE:-false}" = true ] ; then
        MUXDEBUG=$ARTIFACT_DIR/mux-test-ext.$is_testproj.$no_container_vals.$mismatch_namespace.$no_project_tag.log
    else
        MUXDEBUG="/dev/null"
    fi
    echo "DEBUG PRINT is_testproj $is_testproj no_container_vals $no_container_vals ====================================" > $MUXDEBUG

    espod=$es_pod
    if [ $is_testproj -eq 1 -a $no_container_vals -eq 0 ]; then
        # kibana logs with project.testproj tag and given container/pod values
        myfield=""
        mymessage=$uuid_es
        myproject=project.testproj
    else
        # kibana logs with kibana container/pod values
        myfield=""
        mymessage=$uuid_es
        myproject=project.logging
    fi
    if expected=$expected wait_until_cmd_or_err test_count_expected test_count_err 600 ; then
        echo good - $FUNCNAME: found 1 record project $myproject for $uuid_es
        print_message $is_testproj $no_container_vals
    else
        echo failed - $FUNCNAME: not found 1 record project $myproject for $uuid_es
        rc=1
    fi

    if [ $is_testproj -eq 1 ]; then
        # other logs with project.testproj tag
        myfield="MESSAGE"
        myproject=project.testproj
        espod=$es_pod
    elif [ $no_project_tag -eq 1 ]; then
        myfield="MESSAGE"
        myproject=project.mux-undefined
        espod=$es_pod
    else
        myfield=""
        myproject=".operations"
        espod=$es_ops_pod
    fi
    if mymessage=$uuid_es_ops expected=$expected \
            wait_until_cmd_or_err test_count_expected test_count_err 600 ; then
        echo good - $FUNCNAME: found 1 record project $myproject for $uuid_es_ops
        echo good - $FUNCNAME: found 1 record project $myproject for $uuid_es_ops >> $MUXDEBUG
        print_message $is_testproj $no_container_vals
    else
        echo failed - $FUNCNAME: not found 1 record project $myproject for $uuid_es_ops
        echo failed - $FUNCNAME: not found 1 record project $myproject for $uuid_es_ops >> $MUXDEBUG
        rc=1
    fi

    local f_pod=`get_running_pod fluentd`
    local m_pod=`get_running_pod mux`
    oc projects >> $MUXDEBUG
    oc get pods >> $MUXDEBUG
    if [ "$f_pod" != "" ]; then
        echo "FLUENTD LOG" >> $MUXDEBUG
        oc logs $f_pod >> $MUXDEBUG
        echo "FLUENTD CONFIG MAP" >> $MUXDEBUG
        oc get configmap/logging-fluentd -o yaml >> $MUXDEBUG
        echo "FLUENTD CONFIG FILES" >> $MUXDEBUG
        oc exec $f_pod -- ls /etc/fluent/configs.d/openshift >> $MUXDEBUG
        oc exec $f_pod -- ls /etc/fluent/configs.d/user >> $MUXDEBUG
    fi
    if [ "$m_pod" != "" ]; then
        echo "MUX LOG" >> $MUXDEBUG
        oc logs $m_pod >> $MUXDEBUG
        echo "MUX CONFIG MAP" >> $MUXDEBUG
        oc get configmap/logging-mux -o yaml >> $MUXDEBUG
        echo "MUX CONFIG FILES" >> $MUXDEBUG
        oc exec $m_pod -- ls /etc/fluent/configs.d/openshift >> $MUXDEBUG
        oc exec $m_pod -- ls /etc/fluent/configs.d/user >> $MUXDEBUG
    fi
    echo "DEBUG PRINT ENDS ===============================================" >> $MUXDEBUG

    return $rc
}

restart_fluentd() {
    oc label node --all logging-infra-fluentd-
    # wait for fluentd to stop
    wait_for_pod_ACTION stop $fpod
    reset_fluentd_daemonset
    # create the daemonset which will also start fluentd
    oc label node --all logging-infra-fluentd=true
    # wait for fluentd to start
    wait_for_pod_ACTION start fluentd
    fpod=`get_running_pod fluentd`
    oc logs $fpod  > $ARTIFACT_DIR/$fpod.log
}

TEST_DIVIDER="------------------------------------------"

# make sure we are in logging
oc project logging

fpod=`get_running_pod fluentd`

if [ -z "$fpod" ] ; then
    echo Error: fluentd is not running
    exit 1
fi

if [ -z "`get_running_pod kibana`" ] ; then
    echo Error: kibana is not running
    exit 1
fi

if [ -z "`get_running_pod es`" ] ; then
    echo Error: es is not running
    exit 1
fi

# run test to make sure fluentd is working normally 
write_and_verify_logs 1 0 0 || {
    oc get events -o yaml > $ARTIFACT_DIR/all-events.yaml 2>&1
echo $?
}

cleanup() {
    # put back original configuration
    cleanup_forward
    oc get events -o yaml > $ARTIFACT_DIR/all-events.yaml 2>&1
}
trap "cleanup" INT TERM EXIT

echo "------- Test case $SET_CONTAINER_VALS -------"
echo "fluentd forwards kibana and system logs with tag project.testproj.mux and CONTAINER values."
#
# prerequisite: project testproj
# results: logs are stored in project.testproj.*
#              with k8s.namespace_name: testproj
#                   k8s.container_name: mux
#                   k8s.pod_name: logging-mux
#                   (set in update_current_fluentd)
#
update_current_fluentd $SET_CONTAINER_VALS

write_and_verify_logs 1 1 0

cleanup

echo "------- Test case $NO_CONTAINER_VALS -------"
echo "fluentd forwards kibana and system logs with tag project.testproj.mux without CONTAINER values."
#
# prerequisite: project testproj
# results: kibana logs are stored in the default index project.logging with kibana container/pod info.
#          system logs are stored in project.testproj
#                with k8s.namespace_name: testproj
#                     k8s.container_name: mux-mux
#                     k8s.pod_name: mux
#                     (set in mux-post-input-filter-tag.conf)
#
update_current_fluentd $NO_CONTAINER_VALS

write_and_verify_logs 1 1 1

cleanup

echo "------- Test case $MISMATCH_NAMESPACE_TAG -------"
echo "fluentd forwards kibana and system logs with tag project.testproj.mux and CONTAINER values, which namespace names do not match."
#
# prerequisite: project testproj
# results: logs are stored in project.testproj.*
#              with k8s.namespace_name: testproj
#                   k8s.container_name: mux
#                   k8s.pod_name: logging-mux
#                   (set in update_current_fluentd)
#
update_current_fluentd $MISMATCH_NAMESPACE_TAG

write_and_verify_logs 1 1 0 1

cleanup

echo "------- Test case $NO_PROJECT_TAG -------"
echo "fluentd forwards kibana and system logs with tag test.bogus.mux and no CONTAINER values, which will use a namespace of mux-undefined."
#
# results: system logs are stored in project.mux-undefined.*
#

if oc get project mux-undefined > /dev/null 2>&1 ; then
    echo using existing project mux-undefined
else
    oadm new-project mux-undefined --node-selector=''
fi

update_current_fluentd $NO_PROJECT_TAG

write_and_verify_logs 1 0 0 1 1

cleanup

echo "------- Verify cleaned up -------"
write_and_verify_logs 1 0 0

oc delete project testproj
