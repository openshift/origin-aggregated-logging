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

source "$(dirname "${BASH_SOURCE[0]}" )/../lib/init.sh"
source "${OS_O_A_L_DIR}/deployer/scripts/util.sh"

function cleanup() {
  return_code=$?
  os::cleanup::all "${return_code}"
  exit "${return_code}"
}
trap "cleanup" EXIT

if [[ -z "${TEST_ONLY:-}" ]]; then
	"${OS_O_A_L_DIR}/hack/testing/setup.sh"
elif [[ -z "${KUBECONFIG:-}" ]]; then
	os::log::fatal "A \$KUBECONFIG must be specified with \$TEST_ONLY."
fi

expected_failures=(
	"test-fluentd-forward"
	"test-json-parsing"
	"test-es-copy"
	"test-mux"
	"test-upgrade"
	"test-viaq-data-model"
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