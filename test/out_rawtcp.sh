#!/bin/bash

# This is a test suite for the fluentd raw_tcp feature

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::util::environment::use_sudo

FLUENTD_WAIT_TIME=${FLUENTD_WAIT_TIME:-$(( 2 * minute ))}

os::test::junit::declare_suite_start "test/raw-tcp"

update_current_fluentd() {
    # undeploy fluentd
    os::log::debug "$( oc label node --all logging-infra-fluentd- )"
    os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME

    # update configmap logging-fluentd
    # edit so we don't send to ES
    oc get configmap/logging-fluentd -o yaml | sed '/## matches/ a\
    <match **>\
      @type copy\
      @include configs.d/user/raw-tcp.conf\
    </match>' | oc replace -f -
      oc patch configmap/logging-fluentd --type=json --patch '[{ "op": "add", "path": "/data/raw-tcp.conf", "#": "generated config file raw-tcp.conf" }]' 2>&1
      oc patch configmap/logging-fluentd --type=json --patch '[{ "op": "replace", "path": "/data/raw-tcp.conf", "value": "\
  <store>\n\
   @type rawtcp\n\
   flush_interval 1\n\
    <server>\n\
      name logstash\n\
      host logstash.openshift-logging.svc.cluster.local\n\
      port 9400\n\
    </server>\n\
  </store>\n"}]'

    # redeploy fluentd
    os::cmd::expect_success flush_fluentd_pos_files
    os::log::debug "$( oc label node --all logging-infra-fluentd=true )"
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
    fpod=$( get_running_pod logstash )
    if [ -n "${fpod:-}" ] ; then
      os::cmd::try_until_text "oc logs $fpod 2>&1" ".*kubernetes.*" $FLUENTD_WAIT_TIME
    fi
    fpod=$( get_running_pod fluentd ) || :
    artifact_log update_current_fluentd "(oc logs $fpod)"
}

create_forwarding_logstash() {
  oc apply -f $OS_O_A_L_DIR/hack/templates/logstash.yml
  # wait for logstash to start
  os::cmd::try_until_text "oc get pods -l component=logstash" "^logstash-.* Running " 360000
  POD=$( oc get pods -l component=logstash -o name )
  artifact_log create_forwarding_logstash "(oc logs $POD)"
  oc logs $POD 2>&1 | artifact_out || :
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

  # dump the pod before we restart it
  if [ -n "${fpod:-}" ] ; then
    artifact_log cleanup "(oc logs $fpod)"
    oc logs $fpod 2>&1 | artifact_out || :
  fi
  oc get pods 2>&1 | artifact_out
 
  POD=$( oc get pods -l component=fluentd -o name ) || :
  artifact_log cleanup "(oc logs $POD)"
  oc logs $POD 2>&1 | artifact_out || :

  os::log::debug "$( oc label node --all logging-infra-fluentd- 2>&1 || : )"
  os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $FLUENTD_WAIT_TIME
  if [ -n "${savecm:-}" -a -f "${savecm:-}" ] ; then
    os::log::debug "$( oc replace --force -f $savecm )"
  fi
  if [ -n "${saveds:-}" -a -f "${saveds:-}" ] ; then
    os::log::debug "$( oc replace --force -f $saveds )"
  fi

  $mycmd raw-tcp test finished at $( date )

  # Clean up only if it's still around
  os::log::debug "$( oc delete service/logstash 2>&1 || : )"
  os::log::debug "$( oc delete deploymentconfig/logstash 2>&1 || : )"

  os::log::debug "$( oc label node --all logging-infra-fluentd=true 2>&1 || : )"
  os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
  fpod=$( get_running_pod fluentd )
  os::cmd::expect_success wait_for_fluentd_to_catch_up
  os::cmd::expect_success flush_fluentd_pos_files
}
trap "cleanup" EXIT

os::log::info Starting raw-tcp test at $( date )

# make sure fluentd is working normally
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
fpod=$( get_running_pod fluentd )
os::cmd::expect_success wait_for_fluentd_to_catch_up

create_forwarding_logstash
update_current_fluentd
