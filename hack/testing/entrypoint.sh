#!/bin/bash

# This script serves as a common entrypoint for CI infra
# as well as developers looking to run test suites for the
# project. The script can either set up a cluster to test
# or run against a cluster that is already up.
#
# Cluster end-to-end tests will be run first, followed by
# other test suites. If a specific suite or suites are req-
# uested with $SUITE, only that suite will be run.
#
# This script expects the following environment variables:
#  - TEST_ONLY: do not set up a cluster. Must be paired with
#    a $KUEBCONFIG that points to the cluster to test
#  - SUITE: a regex that will choose which test suites are
#    run. Test suite entrypoints exist under hack/testing/
#    with the test- prefix. The regex in $SUITE is a simple
#    filter.
#  - JUNIT_REPORT: generate a jUnit XML report for tests

source "$(dirname "${BASH_SOURCE[0]}" )/../lib/init.sh"
source "${OS_O_A_L_DIR}/deployer/scripts/util.sh"

# HACK HACK HACK
# There seems to be some sort of performance problem - richm 2017-08-15
# not sure what has changed, but now running an all-in-one for CI, with both
# openshift master and node running as systemd services logging to the journal
#, and the default/logging pods, and the os, are spewing too much for fluentd
# to keep up with when it has 100m cpu (default), on a aws m4.xlarge system
# for now, remove the limits on fluentd to unblock the tests
oc get -n logging daemonset/logging-fluentd -o yaml > "${ARTIFACT_DIR}/logging-fluentd-orig.yaml"
if [ -z "${USE_DEFAULT_FLUENTD_CPU_LIMIT:-}" ] ; then
    oc patch -n logging daemonset/logging-fluentd --type=json --patch '[
          {"op":"remove","path":"/spec/template/spec/containers/0/resources/limits/cpu"}]'
fi

# start a fluentd performance monitor
monitor_fluentd_top() {
    while true ; do
        fpod=$( get_running_pod fluentd )
        if [ -n "$fpod" ] ; then
            oc exec $fpod -- top -b -d 1 || :
        else
            # if we got here, the fluentd pod was restarted
            echo $( date --rfc-3339=ns ) fluentd is not running
            sleep 1
        fi
    done > $ARTIFACT_DIR/monitor_fluentd_top.log
}

monitor_fluentd_pos() {
    while true ; do
        if sudo test -s /var/log/journal.pos ; then
            local startts=$( date +%s )
            local count=$( sudo journalctl -c $( sudo cat /var/log/journal.pos ) | wc -l )
            local endts=$( date +%s )
            echo $endts $( expr $endts - $startts ) $count
        else
            echo $( date --rfc-3339=ns ) no /var/log/journal.pos
        fi
        sleep 1
    done > $ARTIFACT_DIR/monitor_fluentd_pos.log
}

monitor_journal_lograte() {
    local interval=60
    while true ; do
        count=$( sudo journalctl -S "$( date +'%Y-%m-%d %H:%M:%S' --date="$interval seconds ago" )" | wc -l )
        echo $( date +%s ) $count
        sleep $interval
    done  > $ARTIFACT_DIR/monitor_journal_lograte.log
}

monitor_fluentd_top & killpids=$!
monitor_fluentd_pos & killpids="$killpids $!"
monitor_journal_lograte & killpids="$killpids $!"

function cleanup() {
  return_code=$?
  kill $killpids
  os::cleanup::all "${return_code}"
  exit "${return_code}"
}
trap "cleanup" EXIT

if [[ -z "${TEST_ONLY:-}" ]]; then
	"${OS_O_A_L_DIR}/hack/testing/setup.sh"
elif [[ -z "${KUBECONFIG:-}" ]]; then
	os::log::fatal "A \$KUBECONFIG must be specified with \$TEST_ONLY."
fi

if [[ -n "${JUNIT_REPORT:-}" ]]; then
	export JUNIT_REPORT_OUTPUT="${LOG_DIR}/raw_test_output.log"
fi

expected_failures=(
	"test-fluentd-forward"
	"test-upgrade"
)

function run_suite() {
	local test="$1"
	suite_name="$( basename "${test}" '.sh' )"
	os::test::junit::declare_suite_start "test/setup/${suite_name}"
	os::cmd::expect_success "oc login -u system:admin"
	os::cmd::expect_success "oc project logging"
	os::test::junit::declare_suite_end

	os::log::info "Logging test suite ${suite_name} started at $( date )"
	ops_cluster="true"
	if "${test}" "${ops_cluster}"; then
		os::log::info "Logging test suite ${suite_name} succeeded at $( date )"
		if grep -q "${suite_name}" <<<"${expected_failures[@]}"; then
			os::log::warning "Logging suite ${suite_name} is expected to fail"
		fi
	else
		os::log::warning "Logging test suite ${suite_name} failed at $( date )"
		if grep -q "${suite_name}" <<<"${expected_failures[@]}"; then
			os::log::info "Logging suite ${suite_name} failure result ignored"
		else
			failed="true"
		fi
	fi
}

suite_selector="${SUITE:-".*"}"
for test in $( find "${OS_O_A_L_DIR}/hack/testing" -type f -name 'check-*.sh' | grep -E "${suite_selector}" | sort ); do
	run_suite "${test}"
done

for test in $( find "${OS_O_A_L_DIR}/hack/testing" -type f -name 'test-*.sh' | grep -E "${suite_selector}" | sort ); do
	run_suite "${test}"
done

if [[ -n "${failed:-}" ]]; then
    exit 1
fi
