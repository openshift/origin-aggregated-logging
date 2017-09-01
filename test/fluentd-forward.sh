#!/bin/bash

# This is a test suite for the fluentd secure_forward feature

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/deployer/scripts/util.sh"
os::util::environment::use_sudo

os::test::junit::declare_suite_start "test/fluentd-forward"

update_current_fluentd() {
    # this will update it so the current fluentd does not send logs to an ES host
    # but instead forwards to the forwarding fluentd

    # undeploy fluentd
    os::log::debug "$( oc label node --all logging-infra-fluentd- )"
    os::cmd::try_until_failure "oc get pod $fpod"

    # edit so we don't send to ES
    oc get configmap/logging-fluentd -o yaml | sed '/## matches/ a\
      <match **>\
        @include configs.d/user/secure-forward.conf\
      </match>' | oc replace -f -

    POD=$( oc get pods -l component=forward-fluentd -o name )
    FLUENTD_FORWARD=$( oc get $POD --template='{{.status.podIP}}' )

    # update configmap secure-forward.conf
    oc patch configmap/logging-fluentd --type=json --patch '[{ "op": "replace", "path": "/data/secure-forward.conf", "value": "\
  @type secure_forward\n\
  self_hostname forwarding-${HOSTNAME}\n\
  shared_key aggregated_logging_ci_testing\n\
  secure no\n\
  buffer_queue_limit \"#{ENV['"'BUFFER_QUEUE_LIMIT'"']}\"\n\
  buffer_chunk_limit \"#{ENV['"'BUFFER_SIZE_LIMIT'"']}\"\n\
  <server>\n\
   host '${FLUENTD_FORWARD}'\n\
   port 24284\n\
  </server>"}]'

    # redeploy fluentd
    os::log::debug "$( oc label node --all logging-infra-fluentd=true )"
    os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
    fpod=$( get_running_pod fluentd )
}

create_forwarding_fluentd() {
    # create forwarding configmap named "logging-forward-fluentd"
    oc create configmap logging-forward-fluentd \
       --from-file=fluent.conf=$OS_O_A_L_DIR/hack/templates/forward-fluent.conf

    # create a directory for file buffering so as not to conflict with fluentd
    if [ ! -d /var/lib/fluentd/forward ] ; then
        sudo mkdir -p /var/lib/fluentd/forward
    fi

    # create forwarding daemonset
    oc get daemonset/logging-fluentd -o yaml | \
        sed -e 's/logging-infra-fluentd: "true"/logging-infra-forward-fluentd: "true"/' \
            -e 's/name: logging-fluentd/name: logging-forward-fluentd/' \
            -e 's/ fluentd/ forward-fluentd/' \
            -e '/image:/ a \
        ports: \
          - containerPort: 24284' | \
        oc create -f -

    # make it use a different hostpath than fluentd
    oc set volumes daemonset/logging-forward-fluentd --add --overwrite \
       --name=filebufferstorage --type=hostPath \
       --path=/var/lib/fluentd/forward --mount-path=/var/lib/fluentd

    os::log::debug "$( oc label node --all logging-infra-forward-fluentd=true )"

    # wait for forward-fluentd to start
    os::cmd::try_until_text "oc get pods -l component=forward-fluentd" "^logging-forward-fluentd-.* Running "
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
    $mycmd fluentd-forward test finished at $( date )

    # Clean up only if it's still around
    os::log::debug "$( oc delete daemonset/logging-forward-fluentd 2>&1 || : )"
    os::log::debug "$( oc delete configmap/logging-forward-fluentd 2>&1 || : )"
    os::log::debug "$( oc label node --all logging-infra-forward-fluentd- 2>&1 || : )"

    # dump the pod before we restart it
    if [ -n "${fpod:-}" ] ; then
        oc logs $fpod > $ARTIFACT_DIR/$fpod.log 2>&1
    fi
    os::log::debug "$( oc label node --all logging-infra-fluentd- 2>&1 || : )"
    os::cmd::try_until_failure "oc get pod $fpod"
    if [ -n "${savecm:-}" -a -f "${savecm:-}" ] ; then
        os::log::debug "$( oc replace --force -f $savecm )"
    fi
    if [ -n "${saveds:-}" -a -f "${saveds:-}" ] ; then
        os::log::debug "$( oc replace --force -f $saveds )"
    fi
    os::log::debug "$( oc label node --all logging-infra-fluentd=true 2>&1 || : )"
    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
    exit $return_code
}
trap "cleanup" EXIT

os::log::info Starting fluentd-forward test at $( date )

# make sure fluentd is working normally
os::cmd::try_until_text "oc get pods -l component=fluentd" "^logging-fluentd-.* Running "
fpod=$( get_running_pod fluentd )
wait_for_fluentd_ready
os::cmd::expect_success wait_for_fluentd_to_catch_up

create_forwarding_fluentd
update_current_fluentd

wait_for_fluentd_ready
os::cmd::expect_success wait_for_fluentd_to_catch_up
