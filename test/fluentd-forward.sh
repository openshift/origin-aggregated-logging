#!/bin/bash

# This is a test suite for the fluentd secure_forward feature

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::util::environment::use_sudo

FLUENTD_WAIT_TIME=${FLUENTD_WAIT_TIME:-$(( 2 * minute ))}

os::test::junit::declare_suite_start "test/fluentd-forward"

update_current_fluentd() {
    cnt=${FORWARDCNT:-1}
    # this will update it so the current fluentd does not send logs to an ES host
    # but instead forwards to the forwarding fluentd

    # undeploy fluentd
    os::log::debug "$( oc label node --all logging-infra-fluentd- )"
    os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME

    FLUENTD_FORWARD=()
    id=0
    while [ $id -lt $cnt ]; do
      POD=$( oc get pods -l component=forward-fluentd${id} -o name )
      FLUENTD_FORWARD[$id]=$( oc get $POD --template='{{.status.podIP}}' )
      artifact_log update_current_fluentd .status.podIP ${FLUENTD_FORWARD[$id]}
      id=$( expr $id + 1 ) || :
    done

    # update configmap secure-forward#.conf
    if [ $cnt -eq 1 ]; then
      # edit so we don't send to ES
      oc get configmap/logging-fluentd -o yaml | sed '/## matches/ a\
      <match **>\
        @type copy\
        @include configs.d/user/secure-forward0.conf\
      </match>' | oc replace -f -
        oc patch configmap/logging-fluentd --type=json --patch '[{ "op": "add", "path": "/data/secure-forward0.conf", "#": "generated config file secure-forward0.conf" }]' 2>&1
        oc patch configmap/logging-fluentd --type=json --patch '[{ "op": "replace", "path": "/data/secure-forward0.conf", "value": "\
  <store>\n\
   @type secure_forward\n\
   self_hostname forwarding-${HOSTNAME}\n\
   shared_key aggregated_logging_ci_testing\n\
   secure no\n\
   buffer_queue_limit \"#{ENV['"'BUFFER_QUEUE_LIMIT'"']}\"\n\
   buffer_chunk_limit \"#{ENV['"'BUFFER_SIZE_LIMIT'"']}\"\n\
   buffer_type file\n\
   buffer_path '/var/lib/fluentd/buffer-fluentd-forward0'\n\
   <server>\n\
    host '${FLUENTD_FORWARD[0]}'\n\
    port 24284\n\
   </server>\n\
  </store>\n"}]'
      else
    # edit so we don't send to ES
    oc get configmap/logging-fluentd -o yaml | sed '/## matches/ a\
      <filter **>\
        @type record_transformer\
        remove_keys _id, viaq_msg_id\
      </filter>\
      <match **>\
        @type copy\
        @include configs.d/user/secure-forward1.conf\
      </match>' | oc replace -f -
        oc patch configmap/logging-fluentd --type=json --patch '[{ "op": "add", "path": "/data/secure-forward1.conf", "#": "generated config file secure-forward1.conf" }]' 2>&1
        oc patch configmap/logging-fluentd --type=json --patch '[{ "op": "replace", "path": "/data/secure-forward1.conf", "value": "\
  <store>\n\
   @type secure_forward\n\
   self_hostname forwarding-${HOSTNAME}\n\
   shared_key aggregated_logging_ci_testing\n\
   secure no\n\
   buffer_queue_limit \"#{ENV['"'BUFFER_QUEUE_LIMIT'"']}\"\n\
   buffer_chunk_limit \"#{ENV['"'BUFFER_SIZE_LIMIT'"']}\"\n\
   buffer_type file\n\
   buffer_path '/var/lib/fluentd/buffer-fluentd-forward0'\n\
   <server>\n\
    host '${FLUENTD_FORWARD[0]}'\n\
    port 24284\n\
   </server>\n\
  </store>\n\
  <store>\n\
   @type secure_forward\n\
   self_hostname forwarding-${HOSTNAME}\n\
   shared_key aggregated_logging_ci_testing\n\
   secure no\n\
   buffer_queue_limit \"#{ENV['"'BUFFER_QUEUE_LIMIT'"']}\"\n\
   buffer_chunk_limit \"#{ENV['"'BUFFER_SIZE_LIMIT'"']}\"\n\
   buffer_type file\n\
   buffer_path '/var/lib/fluentd/buffer-fluentd-forward1'\n\
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

    os::log::debug "$( oc set env daemonset/logging-fluentd FILE_BUFFER_LIMIT=${MY_FILE_BUFFER_LIMIT} BUFFER_SIZE_LIMIT=${MY_BUFFER_SIZE_LIMIT} )"
    # redeploy fluentd
    os::cmd::expect_success flush_fluentd_pos_files
    os::log::debug "$( oc label node --all logging-infra-fluentd=true )"
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
    artifact_log update_current_fluentd $cnt
    fpod=$( get_running_pod fluentd ) || :
    artifact_log update_current_fluentd $cnt "(oc logs $fpod)"
    if [ -n "${fpod:-}" ] ; then
        oc logs $fpod 2>&1 | artifact_out
        id=$( expr $cnt - 1 ) || :
        artifact_log update_current_fluentd $cnt "(/etc/fluent/configs.d/user/secure-forward${id}.conf)"
        oc exec $fpod -- cat /etc/fluent/configs.d/user/secure-forward${id}.conf | artifact_out || :
        artifact_log update_current_fluentd $cnt "(oc get pods)"
        oc get pods 2>&1 | artifact_out
    fi

    # check set BUFFER_QUEUE_LIMIT
    REAL_BUFFER_QUEUE_LIMIT=$( oc set env daemonset/logging-fluentd --list | grep BUFFER_QUEUE_LIMIT ) || :
    REAL_BUFFER_QUEUE_LIMIT=$( echo ${REAL_BUFFER_QUEUE_LIMIT:-""} | awk -F'=' '{print $2}' )

    if [ -z "$REAL_BUFFER_QUEUE_LIMIT" ]; then
        os::log::error Environment variable BUFFER_QUEUE_LIMIT is empty.
    elif [ "$REAL_BUFFER_QUEUE_LIMIT" = "$EXP_BUFFER_QUEUE_LIMIT" ]; then
        os::log::debug "Environment variable BUFFER_QUEUE_LIMIT is correctly set to $EXP_BUFFER_QUEUE_LIMIT."
    else
        os::log::error "Environment variable BUFFER_QUEUE_LIMIT is set to $REAL_BUFFER_QUEUE_LIMIT, which is suppose to be $EXP_BUFFER_QUEUE_LIMIT."
    fi
}

create_forwarding_fluentd() {
  cnt=${FORWARDCNT:-1}
  id=0
  while [ $id -lt $cnt ]; do
    # create forwarding configmap named "logging-forward-fluentd"
    oc create configmap logging-forward-fluentd${id} \
       --from-file=fluent.conf=$OS_O_A_L_DIR/hack/templates/forward-fluent.conf

    # create a directory for file buffering so as not to conflict with fluentd
    if [ ! -d /var/lib/fluentd/forward${id} ] ; then
        sudo mkdir -p /var/lib/fluentd/forward${id}
    fi

    # create forwarding daemonset
    if [ $id -eq 0 ]; then
      oc get daemonset/logging-fluentd -o yaml | \
        sed -e "s/logging-infra-fluentd:/logging-infra-forward-fluentd0:/" \
            -e "s/name: logging-fluentd/name: logging-forward-fluentd0/" \
            -e "s/ fluentd/ forward-fluentd0/" \
            -e '/image:/ a \
        ports: \
          - containerPort: 24284' | \
        oc create -f -
    else
      oc get daemonset/logging-fluentd -o yaml | \
        sed -e "s/logging-infra-fluentd:/logging-infra-forward-fluentd1:/" \
            -e "s/name: logging-fluentd/name: logging-forward-fluentd1/" \
            -e "s/ fluentd/ forward-fluentd1/" \
            -e '/image:/ a \
        ports: \
          - containerPort: 24284' | \
        oc create -f -
    fi

    # make it use a different hostpath than fluentd
    oc set volumes daemonset/logging-forward-fluentd${id} --add --overwrite \
       --name=filebufferstorage --type=hostPath \
       --path=/var/lib/fluentd/forward${id} --mount-path=/var/lib/fluentd

    os::cmd::expect_success flush_fluentd_pos_files
    os::log::debug "$( oc label node --all logging-infra-forward-fluentd${id}=true )"

    # wait for forward-fluentd to start
    os::cmd::try_until_text "oc get pods -l component=forward-fluentd${id}" "^logging-forward-fluentd${id}-.* Running "
    POD=$( oc get pods -l component=forward-fluentd${id} -o name )
    artifact_log create_forwarding_fluentd $cnt "(oc logs $POD)"
    oc logs $POD 2>&1 | artifact_out || :
    id=$( expr $id + 1 )
  done
}

# save current fluentd daemonset
saveds=$( mktemp )
oc get daemonset logging-fluentd -o yaml > $saveds

# save current fluentd configmap
savecm=$( mktemp )
oc get configmap logging-fluentd -o yaml > $savecm

cleanup() {
  local return_code="$?"
  set +e
  if [ $return_code = 0 ] ; then
    mycmd=os::log::info
  else
    mycmd=os::log::error
  fi
  cnt=${FORWARDCNT:-0}
  # dump the pod before we restart it
  if [ -n "${fpod:-}" ] ; then
    artifact_log cleanup "(oc logs $fpod)"
    oc logs $fpod 2>&1 | artifact_out || :
  fi
  oc get pods 2>&1 | artifact_out
  id=0
  while [ $id -lt $cnt ]; do
    POD=$( oc get pods -l component=forward-fluentd${id} -o name ) || :
    artifact_log cleanup $cnt "(oc logs $POD)"
    oc logs $POD 2>&1 | artifact_out || :
    id=$( expr $id + 1 )
  done
  os::log::debug "$( oc label node --all logging-infra-fluentd- 2>&1 || : )"
  os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME
  if [ -n "${savecm:-}" -a -f "${savecm:-}" ] ; then
    os::log::debug "$( oc replace --force -f $savecm )"
  fi
  if [ -n "${saveds:-}" -a -f "${saveds:-}" ] ; then
    os::log::debug "$( oc replace --force -f $saveds )"
  fi
  id=0
  while [ $id -lt $cnt ]; do
    $mycmd fluentd-forward${id} test finished at $( date )

    # Clean up only if it's still around
    os::log::debug "$( oc delete daemonset/logging-forward-fluentd${id} 2>&1 || : )"
    os::log::debug "$( oc delete configmap/logging-forward-fluentd${id} 2>&1 || : )"
    os::log::debug "$( oc label node --all logging-infra-forward-fluentd${id}- 2>&1 || : )"
    id=$( expr $id + 1 )
  done
  os::cmd::expect_success flush_fluentd_pos_files
  os::log::debug "$( oc label node --all logging-infra-fluentd=true 2>&1 || : )"
  if [ $cnt -gt 1 ]; then
    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
  fi
  exit $return_code
}
trap "cleanup" EXIT

os::log::info Starting fluentd-forward test at $( date )

# make sure fluentd is working normally
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
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
