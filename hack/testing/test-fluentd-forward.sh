#! /bin/bash

# test by having a fluentd forward securely to another fluentd (and not ES)
# have that second fluentd send logs to ES
# verify the same way we do now (for ES copy)
# need to create a custom configmap for both fluentd?

if [[ $VERBOSE ]]; then
  set -ex
else
  set -e
  VERBOSE=
fi
set -o nounset
set -o pipefail

if ! type get_running_pod > /dev/null 2>&1 ; then
    . ${HACK_TESTING_DIR}/util.sh
fi

if [[ $# -ne 1 || "$1" = "false" ]]; then
  # assuming not using OPS cluster
  CLUSTER="false"
  ops=
else
  CLUSTER="$1"
  ops="-ops"
fi

ARTIFACT_DIR=${ARTIFACT_DIR:-${TMPDIR:-/tmp}/origin-aggregated-logging}
if [ ! -d $ARTIFACT_DIR ] ; then
    mkdir -p $ARTIFACT_DIR
fi

PROJ_PREFIX=project.

get_test_user_token

cleanup_forward() {

  # Clean up only if it's still around
  oc delete daemonset/logging-forward-fluentd || :

  # Revert configmap if we haven't yet
  if [ -n "$(oc get configmap/logging-fluentd -o yaml | grep '<match \*\*>')" ]; then
    oc get configmap/logging-fluentd -o yaml | sed -e '/<match \*\*>/ d' \
        -e '/@include configs\.d\/user\/secure-forward\.conf/ d' \
        -e '/<\/match>/ d' | oc replace -f -
  fi

  oc patch configmap/logging-fluentd --type=json --patch '[{ "op": "replace", "path": "/data/secure-forward.conf", "value": "\
# @type secure_forward\n\
# self_hostname forwarding-${HOSTNAME}\n\
# shared_key aggregated_logging_ci_testing\n\
#  secure no\n\
#  <server>\n\
#   host ${FLUENTD_FORWARD}\n\
#   port 24284\n\
#  </server>"}]' || :

}

update_current_fluentd() {
  # this will update it so the current fluentd does not send logs to an ES host
  # but instead forwards to the forwarding fluentd

  # undeploy fluentd
  oc label node --all logging-infra-fluentd-

  wait_for_pod_ACTION stop $fpod

  # edit so we don't send to ES
  oc get configmap/logging-fluentd -o yaml | sed '/## matches/ a\
      <match **>\
        @include configs.d/user/secure-forward.conf\
      </match>' | oc replace -f -

  POD=$(oc get pods -l component=forward-fluentd -o name)
  FLUENTD_FORWARD=$(oc get $POD --template='{{.status.podIP}}')

  # update configmap secure-forward.conf
  oc patch configmap/logging-fluentd --type=json --patch '[{ "op": "replace", "path": "/data/secure-forward.conf", "value": "\
  @type secure_forward\n\
  self_hostname forwarding-${HOSTNAME}\n\
  shared_key aggregated_logging_ci_testing\n\
  secure no\n\
  <server>\n\
   host '${FLUENTD_FORWARD}'\n\
   port 24284\n\
  </server>"}]'

  # redeploy fluentd
  oc label node --all logging-infra-fluentd=true

  # wait for fluentd to start
  wait_for_pod_ACTION start fluentd
}

create_forwarding_fluentd() {
 # create forwarding configmap named "logging-forward-fluentd"
 oc create configmap logging-forward-fluentd \
    --from-file=fluent.conf=../templates/forward-fluent.conf

 # create forwarding daemonset
  oc get template/logging-fluentd-template -o yaml | \
    sed -e 's/logging-infra-fluentd: "true"/logging-infra-forward-fluentd: "true"/' \
        -e 's/name: logging-fluentd/name: logging-forward-fluentd/' \
        -e 's/ fluentd/ forward-fluentd/' \
        -e '/image:/ a \
          ports: \
            - containerPort: 24284' | \
    oc new-app -f -

  oc label node --all logging-infra-forward-fluentd=true

  # wait for fluentd to start
  wait_for_pod_ACTION start forward-fluentd
}

write_and_verify_logs() {
    # expected number of matches
    expected=$1

    rc=0
    if ! wait_for_fluentd_to_catch_up "" "" ; then
        rc=1
    fi

    return $rc
}

restart_fluentd() {
    oc label node --all logging-infra-fluentd-
    # wait for fluentd to stop
    wait_for_pod_ACTION stop $fpod
    # create the daemonset which will also start fluentd
    oc label node --all logging-infra-fluentd=true
    # wait for fluentd to start
    wait_for_pod_ACTION start fluentd
}

TEST_DIVIDER="------------------------------------------"

# configure fluentd to just use the same ES instance for the copy
# cause messages to be written to a container - verify that ES contains
# two copies
# cause messages to be written to the system log - verify that OPS contains
# two copies

fpod=`get_running_pod fluentd`

# run test to make sure fluentd is working normally - no forwarding
write_and_verify_logs 1 || {
    oc get events -o yaml > $ARTIFACT_DIR/all-events.yaml 2>&1
    exit 1
}

cleanup() {
    # put back original configuration
    cleanup_forward
    restart_fluentd
}
trap "cleanup" INT TERM EXIT

create_forwarding_fluentd
update_current_fluentd

fpod=`get_running_pod fluentd`

write_and_verify_logs 1 || {
    oc get events -o yaml > $ARTIFACT_DIR/all-events.yaml 2>&1
    exit 1
}

# put back original configuration
cleanup
fpod=`get_running_pod fluentd`

write_and_verify_logs 1 || {
    oc get events -o yaml > $ARTIFACT_DIR/all-events.yaml 2>&1
    exit 1
}
