#!/bin/bash

# This logging test ensures that a log message created
# one hour in the future and added to /var/log/messages
# will show up in the Elasticsearch log as well as that
# all Fluentd pods have the same time-zone as the node.
#
# This script expects the following environment variables:
#  - OAL_ELASTICSEARCH_COMPONENT: the component labels that
#    are used to identify application pods
source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
trap os::test::junit::reconcile_output EXIT
os::util::environment::use_sudo

os::test::junit::declare_suite_start "test/future_dated_log"

fluentd_prior_log_dir="${LOG_DIR}/fluentd/prior"
mkdir -p "${fluentd_prior_log_dir}"

for fluentd_pod in $( oc get pods --selector component=fluentd  -o jsonpath='{ .items[*].metadata.name }' ); do
	os::log::info "Ensuring Fluentd pod ${fluentd_pod} timezone matches node timezone..."
	os::cmd::expect_success_and_text "oc exec ${fluentd_pod} -- date +%Z" "$( date +%Z )"
	oc logs "${fluentd_pod}" > "${fluentd_prior_log_dir}/${fluentd_pod}.log"
done

if docker_uses_journal; then
    os::log::info "The rest of the test is not applicable when using the journal - skipping"
    exit 0
fi

# NOTE: can't use `logger` for this because we need complete
# control over the date and format so have to use sudo to
# write directly to /var/log/messages
message_date="$( date -u +"%b %d %H:%M:%S" --date="1 hour hence" )"
message_uuid="$( uuidgen )"
message="${message_date} localhost ${message_uuid}: ${message_uuid} message from test/future_dated_log"
echo "${message}" | ${USE_SUDO:+sudo} tee -a /var/log/messages >/dev/null

for elasticsearch_pod in $( oc get pods --selector component="${OAL_ELASTICSEARCH_COMPONENT}" -o jsonpath='{ .items[*].metadata.name }' ); do
	os::log::info "Ensuring Elasticsearch pod ${elasticsearch_pod} persisted the message added to /var/log/messages..."
	os::cmd::try_until_text "curl_es '${elasticsearch_pod}' '/.operations*/_count?q=systemd.u.SYSLOG_IDENTIFIER:${message_uuid}' | python -c 'import json, sys; print json.load(sys.stdin)[\"count\"];'" "1"
done

fluentd_posterior_log_dir="${LOG_DIR}/fluentd/posterior"
mkdir -p "${fluentd_posterior_log_dir}"

for fluentd_pod in $( oc get pods --selector component=fluentd  -o jsonpath='{ .items[*].metadata.name }' ); do
	oc logs "${fluentd_pod}" > "${fluentd_posterior_log_dir}/${fluentd_pod}.log"
done

os::log::info "Checking that Fluentd had no new messages..."
os::cmd::expect_success "diff --new-file --text --recursive ${fluentd_prior_log_dir} ${fluentd_posterior_log_dir}"

os::test::junit::declare_suite_end
