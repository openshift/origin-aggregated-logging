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
#  - EXCLUDE_SUITE: a regex that will choose which test suites
#    are not run. Test suite entrypoints exist under hack/testing/
#    with the test- prefix. The regex in $EXCLUDE_SUITE is
#    a simple filter like $SUITE only with opposite effect.
#  - JUNIT_REPORT: generate a jUnit XML report for tests

source "$(dirname "${BASH_SOURCE[0]}" )/../lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"

LOGGING_NS=openshift-logging
if oc get project logging -o name > /dev/null && [ $(oc get dc -n logging -o name | wc -l) -gt 0 ]  ; then
    LOGGING_NS=logging
fi
export LOGGING_NS

# HACK HACK HACK
#
# There seems to be some sort of performance problem - richm 2017-08-15 not
# sure what has changed, but now running an all-in-one for CI, with both
# openshift master and node running as systemd services logging to the
# journal, and the default/logging pods, and the os, are spewing too much for
# fluentd to keep up with when it has 100m cpu (default), on a aws m4.xlarge
# system for now, remove the limits on fluentd to unblock the tests
oc get -n ${LOGGING_NS} daemonset/logging-fluentd -o yaml > "${ARTIFACT_DIR}/logging-fluentd-orig.yaml"
if [[ -z "${USE_DEFAULT_FLUENTD_CPU_LIMIT:-}" && -n "$(oc get -n ${LOGGING_NS} ds logging-fluentd -o jsonpath={.spec.template.spec.containers[0].resources.limits.cpu})" ]] ; then
    oc patch -n ${LOGGING_NS} daemonset/logging-fluentd --type=json --patch '[
          {"op":"remove","path":"/spec/template/spec/containers/0/resources/limits/cpu"}]'
fi

# Make CI run with enabled debug logs for journald (BZ 1505602)
oc set -n ${LOGGING_NS} env ds/logging-fluentd COLLECT_JOURNAL_DEBUG_LOGS=true

# Make CI run with MUX_CLIENT_MODE off by default - individual tests will set
# MUX_CLIENT_MODE=maximal or minimal
oc set -n ${LOGGING_NS} env ds/logging-fluentd MUX_CLIENT_MODE-

# Starting in 3.10, we can no longer mount /var/lib/docker/containers
oc volumes -n ${LOGGING_NS} ds/logging-fluentd --overwrite --add -t hostPath \
    --name=varlibdockercontainers -m /var/lib/docker --path=/var/lib/docker || :

# start a fluentd performance monitor
monitor_fluentd_top() {
    # assumes running in a subshell
    cp $KUBECONFIG $ARTIFACT_DIR/monitor_fluentd_top.kubeconfig
    export KUBECONFIG=$ARTIFACT_DIR/monitor_fluentd_top.kubeconfig
    oc project ${LOGGING_NS} > /dev/null
    while true ; do
        fpod=$( get_running_pod fluentd 2> /dev/null ) || :
        if [ -n "$fpod" ] ; then
            oc exec $fpod -- top -b -d 1 || :
        else
            # if we got here, the fluentd pod was restarted
            echo $( date --rfc-3339=ns ) fluentd is not running
            sleep 1
        fi
    done > $ARTIFACT_DIR/monitor_fluentd_top.log 2>&1
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
    done > $ARTIFACT_DIR/monitor_fluentd_pos.log 2>&1
}

monitor_journal_lograte() {
    local interval=60
    while true ; do
        count=$( sudo journalctl -S "$( date +'%Y-%m-%d %H:%M:%S' --date="$interval seconds ago" )" | wc -l )
        echo $( date +%s ) $count
        sleep $interval
    done  > $ARTIFACT_DIR/monitor_journal_lograte.log 2>&1
}

monitor_es_bulk_stats() {
    local interval=5
    cp $KUBECONFIG $ARTIFACT_DIR/monitor_es_bulk_stats.kubeconfig
    export KUBECONFIG=$ARTIFACT_DIR/monitor_es_bulk_stats.kubeconfig
    oc project ${LOGGING_NS} > /dev/null
    # wait for espod
    local espod=$( get_es_pod es 2> /dev/null ) || :
    while [ -z "${espod}" ] ; do
        sleep 1
        espod=$( get_es_pod es 2> /dev/null ) || :
    done
    es_ver=$( get_es_major_ver ) || :
    bulk_url=$( get_bulk_thread_pool_url $es_ver "v" c r a q s qs )
    while true ; do
        local essvc=$( get_es_svc es 2> /dev/null ) || :
        local esopssvc=$( get_es_svc es-ops 2> /dev/null ) || :
        esopspod=${esopssvc:-$essvc}
        if [ -n "${essvc}" ] ; then
            date -Ins >> $ARTIFACT_DIR/monitor_es_bulk_stats-es.log 2>&1
            curl_es $essvc "${bulk_url}" >> $ARTIFACT_DIR/monitor_es_bulk_stats-es.log 2>&1 || :
        fi
        if [ -n "${esopssvc}" -a "${essvc}" != "${esopssvc}" ] ; then
            date -Ins >> $ARTIFACT_DIR/monitor_es_bulk_stats-es-ops.log 2>&1
            curl_es $esopssvc "${bulk_url}" >> $ARTIFACT_DIR/monitor_es_bulk_stats-es-ops.log 2>&1 || :
        fi
        sleep $interval
    done
}

monitor_fluentd_top & killpids=$!
monitor_fluentd_pos & killpids="$killpids $!"
monitor_journal_lograte & killpids="$killpids $!"
monitor_es_bulk_stats & killpids="$killpids $!"

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

# if there is a script that is expected to fail, add it here
expected_failures=(
    NONE
)

function run_suite() {
	local test="$1"
	suite_name="$( basename "${test}" '.sh' )"
	os::test::junit::declare_suite_start "test/setup/${suite_name}"
	os::cmd::expect_success "oc login -u system:admin"
	os::cmd::expect_success "oc project $LOGGING_NS"
	os::test::junit::declare_suite_end

	os::log::info "Logging test suite ${suite_name} started at $( date )"
	ops_cluster=${ENABLE_OPS_CLUSTER:-"true"}
	if OS_TMP_ENV_SET= LOG_DIR= ARTIFACT_DIR= "${test}" "${ops_cluster}"; then
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

EXCLUDE_SUITE="${EXCLUDE_SUITE:-"$^"}"
for suite_selector in ${SUITE:-".*"} ; do
  for test in $( find "${OS_O_A_L_DIR}/hack/testing" -type f -name 'check-*.sh' | grep -E "${suite_selector}" | grep -Ev "${EXCLUDE_SUITE}" | sort ); do
	run_suite "${test}"
  done
done

for suite_selector in ${SUITE:-".*"} ; do
  for test in $( find "${OS_O_A_L_DIR}/hack/testing" -type f -name 'test-*.sh' | grep -E "${suite_selector}" | grep -Ev "${EXCLUDE_SUITE}" | sort ); do
	run_suite "${test}"
  done
done

if [[ -n "${failed:-}" ]]; then
    exit 1
fi
