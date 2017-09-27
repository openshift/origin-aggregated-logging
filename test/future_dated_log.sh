#!/bin/bash

# This logging test ensures that all Fluentd pods have the
# same time-zone as the node.
#
# This script expects the following environment variables:
#  - OAL_ELASTICSEARCH_COMPONENT: the component labels that
#    are used to identify application pods
source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
trap os::test::junit::reconcile_output EXIT
os::util::environment::use_sudo

os::test::junit::declare_suite_start "test/future_dated_log"

for fluentd_pod in $( oc get pods --selector component=fluentd  -o jsonpath='{ .items[*].metadata.name }' ); do
	os::log::info "Ensuring Fluentd pod ${fluentd_pod} timezone matches node timezone..."
	os::cmd::expect_success_and_text "oc exec ${fluentd_pod} -- date +%Z" "$( date +%Z )"
done

os::test::junit::declare_suite_end
