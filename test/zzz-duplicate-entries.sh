#!/bin/bash

# This is a test suite for testing basic log processing
# functionality and existance of duplicate records when journal rolls over

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::util::environment::use_sudo

os::test::junit::declare_suite_start "test/zzzz-duplicate-entries"

cleanup() {
    local return_code="$?"
    set +e

    if [ -f /etc/systemd/journald.conf.bak ]; then
      sudo mv /etc/systemd/journald.conf.bak /etc/systemd/journald.conf
      sudo systemctl restart systemd-journald
    fi

#    oc label node --all logging-infra-fluentd- 2>&1 | artifact_out || :
#    os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $((second * 120))

    # cleanup fluentd pos file and restart
#    flush_fluentd_pos_files
#    oc label node --all logging-infra-fluentd=true 2>&1 | artifact_out
#    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "

    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
    exit $return_code
}
trap "cleanup" EXIT

# turn off fluentd
#oc label node --all logging-infra-fluentd- 2>&1 | artifact_out || :
#os::cmd::try_until_text "oc get daemonset logging-fluentd -o jsonpath='{ .status.numberReady }'" "0" $((second * 120))

sudo sed -i.bak "s/^.*MaxRetentionSec=.*$/ MaxRetentionSec=30/" /etc/systemd/journald.conf
sudo systemctl restart systemd-journald

sleep 10
#flush_fluentd_pos_files
#oc label node --all logging-infra-fluentd=true 2>&1 | artifact_out
#os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
wait_for_fluentd_to_catch_up

# dump random messages into journal for the next 32 seconds to ensure that we've rolled over
MESSAGES=""
MESSAGE_COUNT=0

START_TIME=$(date +%s)
while [ $(( $(date +%s) - $START_TIME )) -lt 32 ]; do
  MESSAGE="$( openssl rand -hex 16 )"
  MESSAGES="$MESSAGES $MESSAGE"
  logger -i -p local6.info -t $MESSAGE $MESSAGE && artifact_log Pushed for duplicate-entries: $MESSAGE

  let MESSAGE_COUNT=MESSAGE_COUNT+1
done

os::log::info ${MESSAGE_COUNT} messages were generated...

wait_for_fluentd_to_catch_up

# check that fluentd isn't still holding on to rolled over journal files
for file in /var/log/messages-*; do
  os::cmd::expect_success_and_text "stat $file --format=%h" "1"
done

es_svc=$( get_es_svc es )
es_ops_svc=$( get_es_svc es-ops )
es_ops_svc=${es_ops_svc:-$es_svc}
for message in $MESSAGES; do
  qs='{"query":{"term":{"systemd.u.SYSLOG_IDENTIFIER":"'"${message}"'"}}}'
  if os::cmd::try_until_text "curl_es ${es_ops_svc} /.operations.*/_count -X POST -d '$qs' | get_count_from_json" [0-1] $(( 10 * minute )); then
      artifact_log good - found $message
  else
      artifact_log failed - not found $message
  fi
done

sudo mv /etc/systemd/journald.conf.bak /etc/systemd/journald.conf
sudo systemctl restart systemd-journald

sleep 10
