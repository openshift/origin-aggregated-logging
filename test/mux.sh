#!/bin/bash

# test the mux route and service
# - can accept secure_forward from a "client" fluentd

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::util::environment::use_sudo

# only works if there is a mux dc
if oc get dc/logging-mux > /dev/null 2>&1 ; then
    os::log::debug "$( oc get dc/logging-mux )"
else
    os::log::debug "$( oc get dc/logging-mux )"
    os::log::info dc/logging-mux is not present - skipping test
    exit 0
fi

FLUENTD_WAIT_TIME=${FLUENTD_WAIT_TIME:-$(( 2 * minute ))}

os::test::junit::declare_suite_start "test/mux"

es_pod=$( get_es_pod es )
es_ops_pod=$( get_es_pod es-ops )
if [ -n "$es_ops_pod" ] ; then
  ops_cluster=true
else
  ops_cluster=false
  es_ops_pod=$es_pod
fi

extra_mux_artifacts=$ARTIFACT_DIR/mux-artifacts.txt
internal_mux_log() {
    local ts=$1 ; shift
    echo \[${ts}\] "$@" >> $extra_mux_artifacts
}
mux_log() {
    internal_mux_log "$( date --rfc-3339=ns )" "$@"
}
mux_out() {
    local ts="$( date --rfc-3339=ns )"
    while read line ; do
        internal_mux_log "${ts}" $line
    done
}

reset_fluentd_daemonset() {
  # this test only works with MUX_CLIENT_MODE=minimal for now
  os::log::debug "$( oc set env daemonset/logging-fluentd MUX_CLIENT_MODE=minimal )"
  os::log::debug "$( oc set volumes daemonset/logging-fluentd --add --overwrite \
        --name=muxcerts -t secret -m /etc/fluent/muxkeys --secret-name logging-mux 2>&1 )"
}

# OPTIONS:
ENABLE_SECURE_FORWARD=0
SET_CONTAINER_VALS=1
NO_CONTAINER_VALS=2
MISMATCH_NAMESPACE_TAG=3
NO_PROJECT_TAG=4
update_current_fluentd() {
  # this will update it so the current fluentd does not send logs to an ES host
  # but instead forwards to mux
  local myoption=${1:-0}

  # undeploy fluentd
  os::log::debug "$( oc label node --all logging-infra-fluentd- 2>&1 )"
  os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME

  # edit so we don't filter or send to ES
  oc get configmap/logging-fluentd -o yaml | sed '/## filters/ a\
      @include configs.d/user/filter-pre-mux-test-client.conf' | oc replace -f -

  # update configmap filter-pre-mux-test-client.conf
  if [ $myoption -eq $NO_CONTAINER_VALS ]; then
      oc patch configmap/logging-fluentd --type=json --patch '[{ "op": "replace", "path": "/data/filter-pre-mux-test-client.conf", "value": "\
      <filter kubernetes.var.log.containers.**kibana**>\n\
        @type record_transformer\n\
        enable_ruby\n\
        <record>\n\
        CONTAINER_NAME k8s_mux.01234567_logging-kibana_logging_00000000-1111-2222-3333-444444444444_55555555\n\
        CONTAINER_ID_FULL 0123456789012345678901234567890123456789012345678901234567890123\n\
        </record>\n\
      </filter>\n\
      <match kubernetes.var.log.containers.**kibana**>\n\
        @type rewrite_tag_filter\n\
        @label @INGRESS\n\
        rewriterule1 MESSAGE !.+ project.testproj.external\n\
        rewriterule2 MESSAGE .+ project.testproj.external\n\
      </match>\n\
      <match journal>\n\
        @type rewrite_tag_filter\n\
        @label @INGRESS\n\
        rewriterule1 CONTAINER_NAME ^k8s_[^_]+_[^_]+_default_ kubernetes.journal.container._default_\n\
        rewriterule2 MESSAGE .+ project.testproj.external\n\
        rewriterule3 message .+ project.testproj.external\n\
      </match>\n\
      <filter project.testproj.external>\n\
        @type record_transformer\n\
        enable_ruby\n\
        <record>\n\
        @timestamp ${time.strftime(\"%Y-%m-%dT%H:%M:%S%z\")}\n\
        </record>\n\
      </filter>"}]'
  elif [ $myoption -eq $SET_CONTAINER_VALS ]; then
      oc patch configmap/logging-fluentd --type=json --patch '[{ "op": "replace", "path": "/data/filter-pre-mux-test-client.conf", "value": "\
      <match kubernetes.var.log.containers.**kibana**>\n\
        @type rewrite_tag_filter\n\
        @label @INGRESS\n\
        rewriterule1 MESSAGE !.+ project.testproj.external\n\
        rewriterule2 MESSAGE .+ project.testproj.external\n\
      </match>\n\
      <match journal>\n\
        @type rewrite_tag_filter\n\
        @label @INGRESS\n\
        rewriterule1 CONTAINER_NAME ^k8s_[^_]+_[^_]+_default_ kubernetes.journal.container._default_\n\
        rewriterule2 MESSAGE .+ project.testproj.external\n\
        rewriterule3 message .+ project.testproj.external\n\
      </match>\n\
      <filter project.testproj.external>\n\
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
      <filter kubernetes.var.log.containers.**kibana**>\n\
        @type record_transformer\n\
        enable_ruby\n\
        <record>\n\
        CONTAINER_NAME k8s_mux.01234567_logging-kibana_logging_00000000-1111-2222-3333-444444444444_55555555\n\
        CONTAINER_ID_FULL 0123456789012345678901234567890123456789012345678901234567890123\n\
        </record>\n\
      </filter>\n\
      <match kubernetes.var.log.containers.**kibana**>\n\
        @type rewrite_tag_filter\n\
        @label @INGRESS\n\
        rewriterule1 MESSAGE !.+ project.bogus.external\n\
        rewriterule2 MESSAGE .+ project.bogus.external\n\
      </match>\n\
      <match journal>\n\
        @type rewrite_tag_filter\n\
        @label @INGRESS\n\
        rewriterule1 CONTAINER_NAME ^k8s_[^_]+_[^_]+_default_ kubernetes.journal.container._default_\n\
        rewriterule2 MESSAGE .+ project.bogus.external\n\
        rewriterule3 message .+ project.bogus.external\n\
      </match>\n\
      <filter project.bogus.external>\n\
        @type record_transformer\n\
        enable_ruby\n\
        <record>\n\
        @timestamp ${time.strftime(\"%Y-%m-%dT%H:%M:%S%z\")}\n\
        CONTAINER_NAME k8s_mux.01234567_logging-mux_testproj_00000000-1111-2222-3333-444444444444_55555555\n\
        CONTAINER_ID_FULL 0123456789012345678901234567890123456789012345678901234567890123\n\
        </record>\n\
      </filter>"}]'
  elif [ $myoption -eq $NO_PROJECT_TAG ]; then
      oc patch configmap/logging-fluentd --type=json --patch '[{ "op": "replace", "path": "/data/filter-pre-mux-test-client.conf", "value": "\
      <filter kubernetes.var.log.containers.**kibana**>\n\
        @type record_transformer\n\
        enable_ruby\n\
        <record>\n\
        CONTAINER_NAME k8s_mux.01234567_logging-kibana_logging_00000000-1111-2222-3333-444444444444_55555555\n\
        CONTAINER_ID_FULL 0123456789012345678901234567890123456789012345678901234567890123\n\
        </record>\n\
      </filter>\n\
      <match kubernetes.var.log.containers.**kibana**>\n\
        @type rewrite_tag_filter\n\
        @label @INGRESS\n\
        rewriterule1 MESSAGE !.+ test.bogus.external\n\
        rewriterule2 MESSAGE .+ test.bogus.external\n\
      </match>\n\
      <match journal>\n\
        @type rewrite_tag_filter\n\
        @label @INGRESS\n\
        rewriterule1 CONTAINER_NAME ^k8s_[^_]+_[^_]+_default_ kubernetes.journal.container._default_\n\
        rewriterule2 MESSAGE .+ test.bogus.external\n\
        rewriterule3 message .+ test.bogus.external\n\
      </match>\n\
      <filter test.bogus.external>\n\
        @type record_transformer\n\
        enable_ruby\n\
        <record>\n\
        @timestamp ${time.strftime(\"%Y-%m-%dT%H:%M:%S%z\")}\n\
        </record>\n\
      </filter>"}]'
  else
      os::log::info "Enabling secure forward"
  fi

  reset_fluentd_daemonset

  os::cmd::expect_success flush_fluentd_pos_files
  os::log::debug "$( oc label node --all logging-infra-fluentd=true )"
  os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
  fpod=$( get_running_pod fluentd )
}

print_message() {
    os::log::debug "$( curl_es $es_pod /project.${myproject}.*/_search?${myfield}:${mymessage} )"
    os::log::debug "$( curl_es $es_pod /_cat/indices?v )"
    if [ "$es_pod" != "$es_ops_pod" ] ; then
        os::log::debug "$( curl_es $es_ops_pod /_cat/indices?v )"
    fi
}

write_and_verify_logs() {
    # expected number of matches
    local expected=$1
    local is_testproj=$2
    local no_container_vals=$3
    local mismatch_namespace=${4:-0}
    local no_project_tag=${5:-0}

    local uuid_es=$( uuidgen )
    local uuid_es_ops=$( uuidgen )

    wait_for_fluentd_ready

    oc get pods | grep fluentd | mux_out

    add_test_message $uuid_es
    local fcursor_before=$( sudo cat /var/log/journal.pos )
    oc get pods | grep fluentd | mux_out
    logger -i -p local6.info -t $uuid_es_ops $uuid_es_ops
    # get the cursor of this record - compare to the fluentd journal cursor position
    local reccursor=$( sudo journalctl -o export -t $uuid_es_ops | awk -F__CURSOR= '/^__CURSOR=/ {print $2}' )
    oc get pods | grep fluentd | mux_out
    local fcursor_after=$( sudo cat /var/log/journal.pos )
    mux_log Cursors:
    mux_log "  " before $fcursor_before
    mux_log "  " record $reccursor
    mux_log "  " after $fcursor_after
    oc get pods | grep fluentd | mux_out

    local rc=0

    os::log::debug "is_testproj $is_testproj no_container_vals $no_container_vals ===================================="

    local espod=$es_pod
    local mymessage="GET /$uuid_es 404 "
    if [ $is_testproj -eq 1 -a $no_container_vals -eq 0 ]; then
        # kibana logs with project.testproj tag and given container/pod values
        local myproject=project.testproj
    else
        # kibana logs with kibana container/pod values
        local myproject=project.logging
    fi
    # could be different fields depending on the container log driver - so just
    # search for the exact phrase in all fields
    local startqs='{"query":{"bool":{"filter":{"match_phrase":{"_all":"'"${mymessage}"'"}},"must_not":['
    local comma=""
    # make sure record does not have any of the following fields:
    # docker,kubernetes,CONTAINER_NAME,CONTAINER_ID_FULL,mux_namespace_name,mux_need_k8s_meta,namespace_name,namespace_uuid
    for notfield in docker kubernetes CONTAINER_NAME CONTAINER_ID_FULL mux_namespace_name \
                    mux_need_k8s_meta namespace_name namespace_uuid ; do
        startqs="${startqs}${comma}{\"exists\":{\"field\":\"${notfield}\"}}"
        comma=","
    done
    local qs="${startqs}]}}}"
    os::log::debug "query string is $qs"
    mux_log start $( date ) $( date +%s )
    if ! os::cmd::try_until_text "curl_es $espod /${myproject}.*/_count -XPOST -d '$qs' | get_count_from_json" "^${expected}\$" "$(( 10*minute ))" ; then
        mux_log end $( date ) $( date +%s )
        qs='{"query":{"bool":{"filter":{"match_phrase":{"_all":"'"${mymessage}"'"}}}}}'
        curl_es $espod /${myproject}.*/_count -XPOST -d "$qs" | python -mjson.tool | mux_out
        # grab the first and last records in the index
        curl_es $espod /${myproject}.*/_search?sort=@timestamp:asc\&size=1 | python -mjson.tool | mux_out
        curl_es $espod /${myproject}.*/_search?sort=@timestamp:desc\&size=1 | python -mjson.tool | mux_out
        if docker_uses_journal ; then
            mux_log First matching record:
            sudo journalctl | grep -m 1 $uuid_es | mux_out || :
            mux_log Last matching record:
            sudo journalctl -r | grep -m 1 $uuid_es | mux_out || :
        else
            mux_log matching record:
            sudo find /var/log/containers -name \*.log -exec grep $uuid_es {} /dev/null \; | mux_out || :
        fi
        exit 1
    fi

    if [ $is_testproj -eq 1 ]; then
        # other logs with project.testproj tag
        local myfield="SYSLOG_IDENTIFIER"
        myproject=project.testproj
        espod=$es_pod
    elif [ $no_project_tag -eq 1 ]; then
        local myfield="SYSLOG_IDENTIFIER"
        myproject=project.mux-undefined
        espod=$es_pod
    else
        local myfield="systemd.u.SYSLOG_IDENTIFIER"
        myproject=".operations"
        espod=$es_ops_pod
    fi
    mymessage=$uuid_es_ops
    mux_log start $( date ) $( date +%s )
    if ! os::cmd::try_until_text "curl_es $espod /${myproject}.*/_count?q=${myfield}:$mymessage | get_count_from_json" "^${expected}\$" "$(( 10*minute ))" ; then
        mux_log end $( date ) $( date +%s )
        curl_es $espod /${myproject}.*/_count?q=${myfield}:$mymessage | python -mjson.tool | mux_out
        # grab the first and last records in the index
        curl_es $espod /${myproject}.*/_search?sort=@timestamp:asc\&size=1 | python -mjson.tool | mux_out
        curl_es $espod /${myproject}.*/_search?sort=@timestamp:desc\&size=1 | python -mjson.tool | mux_out
        # find the record in the journal
        sudo journalctl -o export -t $uuid_es_ops | mux_out || :
        exit 1
    fi
    os::cmd::expect_success_and_not_text "curl_es $es_pod /_cat/indices" "project.default"
    os::cmd::expect_success_and_not_text "curl_es $es_ops_pod /_cat/indices" "project.default"
}

reset_ES_HOST() {
    os::cmd::expect_success "oc set env dc logging-mux $1 $2"
    os::log::debug $( oc get pods -l component=mux )
    oc rollout status -w dc/logging-mux # wait for mux to be redeployed
    os::cmd::try_until_text "oc get pods -l component=mux" "^logging-mux-.* Running "
    muxpod=$( get_running_pod mux )
}

cleanup() {
    local return_code="$?"
    set +e

    # In case test failed in Test case FILE_BUFFER_STORAGE_TYPE: $MUX_FILE_BUFFER_STORAGE_TYPE 
    # reset ES_HOST and OPS_HOST
    reset_ES_HOST $ES_HOST_BAK $OPS_HOST_BAK

    if [ $return_code = 0 ] ; then
        mycmd=os::log::info
    else
        mycmd=os::log::error
        muxout=$ARTIFACT_DIR/mux-artifacts.txt
        oc projects >> $muxout 2>&1
        oc get pods >> $muxout 2>&1
        if [ -n "$fpod" ]; then
            oc get configmap/logging-fluentd -o yaml > $ARTIFACT_DIR/mux.fluentd.configmap.yaml
            oc exec $fpod -- ls -alrtF /etc/fluent/configs.d/openshift >> $muxout 2>&1
            oc exec $fpod -- ls -alrtF /etc/fluent/configs.d/user >> $muxout 2>&1
        fi
        if [ -n "${muxpod:-}" ]; then
            oc logs $muxpod > $ARTIFACT_DIR/mux.mux.pod.log
            oc get configmap/logging-mux -o yaml > $ARTIFACT_DIR/mux.mux.configmap.yaml
            oc exec $muxpod -- ls -alrtF /etc/fluent/configs.d/openshift >> $muxout 2>&1
            oc exec $muxpod -- ls -alrtF /etc/fluent/configs.d/user >> $muxout 2>&1
        fi
    fi
    $mycmd mux test finished at $( date )
    # get indices at the end
    curl_es $es_pod /_cat/indices > $ARTIFACT_DIR/es.indices.after 2>&1
    curl_es $es_ops_pod /_cat/indices > $ARTIFACT_DIR/es-ops.indices.after 2>&1
    # dump the pod before we restart it
    if [ -n "${fpod:-}" ] ; then
        oc logs $fpod > $ARTIFACT_DIR/mux.$fpod.log 2>&1
    fi
    os::log::debug "$( oc label node --all logging-infra-fluentd- 2>&1 || : )"
    os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME
    if [ -n "${savecm:-}" -a -f "${savecm:-}" ] ; then
        os::log::debug "$( oc replace --force -f $savecm )"
    fi
    if [ -n "${saveds:-}" -a -f "${saveds:-}" ] ; then
        os::log::debug "$( oc replace --force -f $saveds )"
    fi
    # delete indices created by this test
    curl_es $es_pod /project.testproj.* -XDELETE
    curl_es $es_pod /project.default.* -XDELETE
    curl_es $es_pod /project.mux-undefined.* -XDELETE
    os::cmd::expect_success flush_fluentd_pos_files
    os::log::debug "$( oc label node --all logging-infra-fluentd=true 2>&1 || : )"
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
    os::log::debug "$( oc delete project testproj 2>&1 || : )"
    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
    exit $return_code
}
trap "cleanup" EXIT

# save current fluentd daemonset
saveds=$( mktemp )
oc get daemonset logging-fluentd -o yaml > $saveds

# save current fluentd configmap
savecm=$( mktemp )
oc get configmap logging-fluentd -o yaml > $savecm

os::log::info Starting mux test at $( date )

if oc get project testproj > /dev/null 2>&1 ; then
    os::log::info using existing project testproj
else
    os::log::debug "$( oadm new-project testproj --node-selector='' 2>&1 )"
fi

# save indices at the start
curl_es $es_pod /_cat/indices > $ARTIFACT_DIR/es.indices.before 2>&1
curl_es $es_ops_pod /_cat/indices > $ARTIFACT_DIR/es-ops.indices.before 2>&1

muxpod=$( get_running_pod mux )

MUX_FILE_BUFFER_STORAGE_TYPE=${MUX_FILE_BUFFER_STORAGE_TYPE:-emptydir}
if [ "$MUX_FILE_BUFFER_STORAGE_TYPE" = "pvc" ]; then
    os::log::debug file_buffer_storage_type: pvc
    os::log::debug "$( oc get pv )"
    os::log::debug "$( oc get pvc )"
fi

ES_HOST_BAK=$( oc set env --list dc/logging-mux | grep \^ES_HOST= )
OPS_HOST_BAK=$( oc set env --list dc/logging-mux | grep \^OPS_HOST= )

# make sure fluentd is working normally
fpod=$( get_running_pod fluentd )
wait_for_fluentd_to_catch_up

if [ "$MUX_FILE_BUFFER_STORAGE_TYPE" = "pvc" -o "$MUX_FILE_BUFFER_STORAGE_TYPE" = "hostmount" ]; then
    os::log::info "------- Test case FILE_BUFFER_STORAGE_TYPE: $MUX_FILE_BUFFER_STORAGE_TYPE -------"

    update_current_fluentd $ENABLE_SECURE_FORWARD

    # set ES_HOST and OPS_HOST to non-existing hostname
    if [ "$ops_cluster" = "true" ]; then
        reset_ES_HOST ES_HOST=bogus OPS_HOST=bogus_ops
    else
        reset_ES_HOST ES_HOST=bogus OPS_HOST=bogus
    fi

    uuid_es=$( uuidgen )
    uuid_es_ops=$( uuidgen )

    logger -i -p local6.info -t $uuid_es_ops $uuid_es_ops
    add_test_message $uuid_es

    # wait for the test messages are in the buffer
    muxpod=$( get_running_pod mux )
    if [ "$ops_cluster" = "true" ]; then
       ops_filename="output-es-ops-config.output_ops_tag"
    else
       ops_filename="output-es-config.output_tag"
    fi
    retry="true"
    while [ "$retry" = "true" ]; do
        ops_logs=$( oc exec $muxpod -- ls /var/lib/fluentd/ | egrep $ops_filename ) || :
        if [ -z "$ops_logs" ]; then
            sleep 1
            continue
        fi
        for ops_log in $ops_logs; do
            found=$( oc exec $muxpod -- strings /var/lib/fluentd/$ops_log | egrep $uuid_es_ops ) || :
            if [ -n "$found" ]; then
                retry="false"
                break
            fi
        done
    done
    os::log::debug "$( oc exec $muxpod -- ls -l /var/lib/fluentd )"
    os::log::debug "$( oc logs $muxpod )"

    # set ES_HOST and OPS_HOST to original
    reset_ES_HOST $ES_HOST_BAK $OPS_HOST_BAK

    # wait for the file buffer disappears once
    os::cmd::try_until_text "oc exec $muxpod -- ls -l /var/lib/fluentd" "total 0" $FLUENTD_WAIT_TIME
    os::log::debug "$( oc exec $muxpod -- ls -l /var/lib/fluentd )"
    os::log::debug "$( oc logs $muxpod )"

    # kibana logs with kibana container/pod values
    myproject=project.logging
    mymessage="GET /${uuid_es} 404 "
    qs='{"query":{"match_phrase":{"message":"'"${mymessage}"'"}}}'
    os::log::debug "Check kibana log - message \"${mymessage}\""
    os::cmd::try_until_success "curl_es $es_pod /${myproject}.*/_count -XPOST -d '$qs' | get_count_from_json | egrep -q '^1$'" "$(( 10*minute ))"

    myproject=.operations
    mymessage=$uuid_es_ops
    qs='{"query":{"term":{"systemd.u.SYSLOG_IDENTIFIER":"'"${mymessage}"'"}}}'
    os::log::debug "Check system log - SYSLOG_IDENTIFIER \"${mymessage}\""
    os::cmd::try_until_success "curl_es $es_ops_pod /${myproject}.*/_count -XPOST -d '$qs' | get_count_from_json | egrep -q '^1$'" "$(( 10*minute ))"
fi

os::log::info "------- Test case $SET_CONTAINER_VALS -------"
os::log::info "fluentd forwards kibana and system logs with tag project.testproj.external and CONTAINER values."
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

os::log::info "------- Test case $NO_CONTAINER_VALS -------"
os::log::info "fluentd forwards kibana and system logs with tag project.testproj.external without CONTAINER values."
#
# prerequisite: project testproj
# results: kibana logs are stored in the default index project.logging with kibana container/pod info.
#          system logs are stored in project.testproj
#                with k8s.namespace_name: testproj
#                     k8s.container_name: mux-mux
#                     k8s.pod_name: mux
#                     (set in update_current_fluentd)
#
update_current_fluentd $NO_CONTAINER_VALS

write_and_verify_logs 1 1 1

os::log::info "------- Test case $MISMATCH_NAMESPACE_TAG -------"
os::log::info "fluentd forwards kibana and system logs with tag project.testproj.external and CONTAINER values, which namespace names do not match."
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

os::log::info "------- Test case $NO_PROJECT_TAG -------"
os::log::info "fluentd forwards kibana and system logs with tag test.bogus.external and no CONTAINER values, which will use a namespace of mux-undefined."
#
# results: system logs are stored in project.mux-undefined.*
#

if oc get project mux-undefined > /dev/null 2>&1 ; then
    os::log::info using existing project mux-undefined
else
    os::log::debug "$( oadm new-project mux-undefined --node-selector='' 2>&1 )"
fi

update_current_fluentd $NO_PROJECT_TAG

write_and_verify_logs 1 0 0 1 1
