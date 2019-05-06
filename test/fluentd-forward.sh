#!/bin/bash

# This is a test suite for the fluentd forward feature

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::util::environment::use_sudo

FLUENTD_WAIT_TIME=${FLUENTD_WAIT_TIME:-$(( 2 * minute ))}

os::test::junit::declare_suite_start "test/fluentd-forward"

extra_artifacts=$ARTIFACT_DIR/fluentd-forward-artifacts.txt

update_current_fluentd() {
    cnt=${FORWARDCNT:-1}
    # this will update it so the current fluentd does not send logs to an ES host
    # but instead forwards to the forwarding fluentd

    # undeploy fluentd
    stop_fluentd "" $FLUENTD_WAIT_TIME 2>&1 | artifact_out

    FLUENTD_FORWARD=()
    id=0
    while [ $id -lt $cnt ]; do
      POD=$( get_running_pod forward-fluentd${id} )
      FLUENTD_FORWARD[$id]=$( oc get pod $POD --template='{{.status.podIP}}' )
      artifact_log update_current_fluentd .status.podIP ${FLUENTD_FORWARD[$id]}
      id=$( expr $id + 1 ) || :
    done

    # update configmap secure-forward#.conf
    if [ $cnt -eq 1 ]; then
      # edit so we don't send to ES
      oc get $fluentd_cm -o yaml | sed -e '/## matches/ a\
      <match **>\
        @type copy\
        @include configs.d/user/secure-forward0.conf\
      </match>' -e '/output-operations.conf/d' -e '/output-applications.conf/d' | oc replace -f -
        oc patch $fluentd_cm --type=json --patch '[{ "op": "add", "path": "/data/secure-forward0.conf", "#": "generated config file secure-forward0.conf" }]' 2>&1
        oc patch $fluentd_cm --type=json --patch '[{ "op": "replace", "path": "/data/secure-forward0.conf", "value": "\
  <store>\n\
   @type forward\n\
   @id fluentd-forward0\n\
   <security>\n\
     self_hostname forwarding-${HOSTNAME}\n\
     shared_key aggregated_logging_ci_testing\n\
   </security>\n\
   <buffer>\n\
     @type file\n\
     path '/var/lib/fluentd/forward0'\n\
     queued_chunks_limit_size \"#{ENV['"'BUFFER_QUEUE_LIMIT'"']}\"\n\
     chunk_limit_size \"#{ENV['"'BUFFER_SIZE_LIMIT'"']}\"\n\
   </buffer>\n\
   <server>\n\
    host '${FLUENTD_FORWARD[0]}'\n\
    port 24284\n\
   </server>\n\
  </store>\n"}]'
      else
    # edit so we don't send to ES
    oc get $fluentd_cm -o yaml | sed -e '/## matches/ a\
      <filter **>\
        @type record_transformer\
        remove_keys _id, viaq_msg_id\
      </filter>\
      <match **>\
        @type copy\
        @include configs.d/user/secure-forward1.conf\
      </match>' -e '/output-operations.conf/d' -e '/output-applications.conf/d' | oc replace -f -
        oc patch $fluentd_cm --type=json --patch '[{ "op": "add", "path": "/data/secure-forward1.conf", "#": "generated config file secure-forward1.conf" }]' 2>&1
        oc patch $fluentd_cm --type=json --patch '[{ "op": "replace", "path": "/data/secure-forward1.conf", "value": "\
  <store>\n\
   @type forward\n\
   @id fluentd-forward0\n\
   <security>\n\
     self_hostname forwarding-${HOSTNAME}\n\
     shared_key aggregated_logging_ci_testing\n\
   </security>\n\
   <buffer>\n\
     @type file\n\
     path '/var/lib/fluentd/forward0'\n\
     queued_chunks_limit_size \"#{ENV['"'BUFFER_QUEUE_LIMIT'"']}\"\n\
     chunk_limit_size \"#{ENV['"'BUFFER_SIZE_LIMIT'"']}\"\n\
   </buffer>\n\
   <server>\n\
    host '${FLUENTD_FORWARD[0]}'\n\
    port 24284\n\
   </server>\n\
  </store>\n\
  <store>\n\
   @type forward\n\
   @id fluentd-forward1\n\
   <security>\n\
     self_hostname forwarding-${HOSTNAME}\n\
     shared_key aggregated_logging_ci_testing\n\
   </security>\n\
   <buffer>\n\
     @type file\n\
     path '/var/lib/fluentd/forward1'\n\
     queued_chunks_limit_size \"#{ENV['"'BUFFER_QUEUE_LIMIT'"']}\"\n\
     chunk_limit_size \"#{ENV['"'BUFFER_SIZE_LIMIT'"']}\"\n\
   </buffer>\n\
   <server>\n\
    host '${FLUENTD_FORWARD[1]}'\n\
    port 24284\n\
   </server>\n\
  </store>\n"}]'
      fi

    # set FILE_BUFFER_LIMIT 256Mi; BUFFER_SIZE_LIMIT 8Mi.
    # Note: FILE_BUFFER_LIMIT size is set for each output.
    MY_FILE_BUFFER_LIMIT=256Mi
    MY_BUFFER_SIZE_LIMIT=8Mi
    # 256/8
    EXP_BUFFER_QUEUE_LIMIT=$( expr 256 / 8 )

    oc set env $fluentd_ds FILE_BUFFER_LIMIT=${MY_FILE_BUFFER_LIMIT} BUFFER_SIZE_LIMIT=${MY_BUFFER_SIZE_LIMIT} 2>&1 | artifact_out
    # redeploy fluentd
    start_fluentd true 2>&1 | artifact_out
    artifact_log update_current_fluentd $cnt
    fpod=$( get_running_pod fluentd ) || :
    artifact_log update_current_fluentd $cnt
    oc get pods 2>&1 | artifact_out || :
    if [ -n "${fpod:-}" ] ; then
        get_fluentd_pod_log $fpod > $ARTIFACT_DIR/$fpod.1.log
        id=$( expr $cnt - 1 ) || :
        artifact_log update_current_fluentd $cnt "(/etc/fluent/configs.d/user/secure-forward${id}.conf)"
        oc exec $fpod -- cat /etc/fluent/configs.d/user/secure-forward${id}.conf | artifact_out || :
        artifact_log update_current_fluentd $cnt
        oc get pods 2>&1 | artifact_out || :
    fi

    # check set BUFFER_QUEUE_LIMIT
    REAL_BUFFER_QUEUE_LIMIT=$( oc set env $fluentd_ds --list | grep BUFFER_QUEUE_LIMIT ) || :
    REAL_BUFFER_QUEUE_LIMIT=$( echo ${REAL_BUFFER_QUEUE_LIMIT:-""} | awk -F'=' '{print $2}' )

    if [ -z "$REAL_BUFFER_QUEUE_LIMIT" ]; then
        os::log::error Environment variable BUFFER_QUEUE_LIMIT is empty.
    elif [ "$REAL_BUFFER_QUEUE_LIMIT" = "$EXP_BUFFER_QUEUE_LIMIT" ]; then
        artifact_log "Environment variable BUFFER_QUEUE_LIMIT is correctly set to $EXP_BUFFER_QUEUE_LIMIT."
    else
        os::log::error "Environment variable BUFFER_QUEUE_LIMIT is set to $REAL_BUFFER_QUEUE_LIMIT, which is suppose to be $EXP_BUFFER_QUEUE_LIMIT."
    fi
}

create_forward_ds_from_fluentd_ds() {
  local cnt=$1
  oc get $fluentd_ds -o yaml | \
    sed -e "s/logging-infra-fluentd:/logging-infra-forward-fluentd${cnt}:/" \
        -e "s/name: logging-fluentd/name: logging-forward-fluentd${cnt}/" \
        -e "s/name: fluentd-elasticsearch/name: logging-forward-fluentd${cnt}/" \
        -e "s/name: fluentd/name: logging-forward-fluentd${cnt}/" \
        -e "s/component: fluentd/component: forward-fluentd${cnt}/" \
        -e "s/logging-infra: fluentd/logging-infra: forward-fluentd${cnt}/" \
        -e "s/containerName: fluentd-elasticsearch/containerName: logging-forward-fluentd${cnt}/" \
        -e "s/containerName: fluentd/containerName: logging-forward-fluentd${cnt}/" \
        -e '/image:/ a \
        ports: \
          - containerPort: 24284' | \
    oc create -f - 2>&1 | artifact_out
}

create_forwarding_fluentd() {
  cnt=${FORWARDCNT:-1}
  id=0
  while [ $id -lt $cnt ]; do
    # create forwarding configmap named "logging-forward-fluentd"
    if [ ${FORWARDCNT:-1} -eq 2 ] ; then
      # add genid filter
      genid="--from-file=filter-post-genid.conf=$OS_O_A_L_DIR/fluentd/configs.d/openshift/filter-post-genid.conf"
    fi
    oc create configmap logging-forward-fluentd${id} ${genid:-} \
       --from-file=fluent.conf=$OS_O_A_L_DIR/hack/templates/forward-fluent.conf 2>&1 | artifact_out

    # create a directory for file buffering so as not to conflict with fluentd
    if ! oal_sudo test -d /var/lib/fluentd-forward${id} ; then
        oal_sudo mkdir -p /var/lib/fluentd-forward${id}
    fi

    # create forwarding daemonset
    create_forward_ds_from_fluentd_ds $id

    # make it use a different hostpath than fluentd
    oc set volumes daemonset/logging-forward-fluentd${id} --add --overwrite \
       --name=filebufferstorage --type=hostPath \
       --path=/var/lib/fluentd-forward${id} --mount-path=/var/lib/fluentd 2>&1 | artifact_out
    # make it use a different log file than fluentd
    oc set env daemonset/logging-forward-fluentd${id} LOGGING_FILE_PATH=/var/log/fluentd/forward.$id.log 2>&1 | artifact_out
    oc label node -l logging-infra-fluentd=true logging-infra-forward-fluentd${id}=true 2>&1 | artifact_out

    # wait for forward-fluentd to start
    os::cmd::try_until_text "get_running_pod forward-fluentd${id}" "forward-fluentd${id}"
    POD=$( get_running_pod forward-fluentd${id} )
    artifact_log create_forwarding_fluentd $cnt
    get_fluentd_pod_log $POD /var/log/fluentd/forward.$id.log > $ARTIFACT_DIR/fluentd-forward.$id.log
    id=$( expr $id + 1 )
  done
}

# save current fluentd daemonset
saveds=$( mktemp )
oc get $fluentd_ds -o yaml > $saveds

# save current fluentd configmap
savecm=$( mktemp )
oc get $fluentd_cm -o yaml > $savecm

cleanup() {
  local return_code="$?"
  set +e
  if [ $return_code = 0 ] ; then
    mycmd=os::log::info
  else
    mycmd=os::log::error
  fi
  cnt=${FORWARDCNT:-0}
  local do_exit=false
  if [ $cnt -eq 2 -o $return_code -ne 0 ] ; then
    do_exit=true
    $mycmd fluentd-forward test finished at $( date )
  fi
  # dump the pod before we restart it
  if [ -n "${fpod:-}" ] ; then
    get_fluentd_pod_log $fpod > $ARTIFACT_DIR/$fpod.cleanup.log
  fi
  oc get pods 2>&1 | artifact_out
  id=0
  while [ $id -lt $cnt ]; do
    POD=$( get_running_pod forward-fluentd${id} ) || :
    artifact_log cleanup $cnt
    if [ -n "$POD" ] ; then
      get_fluentd_pod_log $POD /var/log/fluentd/fluentd.$id.log > $ARTIFACT_DIR/$fpod.$id.cleanup.log 2>&1
    fi
    id=$( expr $id + 1 )
  done
  stop_fluentd "${fpod:-}" $FLUENTD_WAIT_TIME 2>&1 | artifact_out || :
  if [ -n "${savecm:-}" -a -f "${savecm:-}" ] ; then
    oc replace --force -f $savecm 2>&1 | artifact_out
  fi
  if [ -n "${saveds:-}" -a -f "${saveds:-}" ] ; then
    oc replace --force -f $saveds 2>&1 | artifact_out
  fi
  id=0
  while [ $id -lt $cnt ]; do
    os::log::info Cleaning up forward-fluentd${id}
    # Clean up only if it's still around
    oc label node --all logging-infra-forward-fluentd${id}- 2>&1 | artifact_out
    oc delete daemonset/logging-forward-fluentd${id} 2>&1 | artifact_out
    oc delete configmap/logging-forward-fluentd${id} 2>&1 | artifact_out
    id=$( expr $id + 1 )
  done
  start_fluentd true 2>&1 | artifact_out
  if [ $do_exit = true ]; then
    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
    exit $return_code
  fi
  set -e
}
trap "cleanup" EXIT

os::log::info Starting fluentd-forward test at $( date )

# make sure fluentd is working normally
os::cmd::try_until_text "get_running_pod fluentd" "fluentd"
fpod=$( get_running_pod fluentd )
wait_for_fluentd_to_catch_up

# FORWARDCNT must be 1 or 2
FORWARDCNT=1
create_forwarding_fluentd
update_current_fluentd
wait_for_fluentd_to_catch_up
cleanup

FORWARDCNT=2
create_forwarding_fluentd
update_current_fluentd
wait_for_fluentd_to_catch_up '' '' 2
