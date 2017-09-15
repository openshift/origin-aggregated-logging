#!/bin/bash

# Test script that loads dashboards
source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
trap os::test::junit::reconcile_output EXIT
os::util::environment::use_sudo

os::test::junit::declare_suite_start "test/kibana_dashboards"

if [ -n "${DEBUG:-}" ] ; then
    set -x
    curl_output() {
        python -mjson.tool
    }
else
    curl_output() {
        cat > /dev/null 2>&1
    }
fi

espod=$( oc get pods --selector component=es -o jsonpath='{ .items[*].metadata.name }' )
esopspod=$( oc get pods --selector component=es-ops -o jsonpath='{ .items[*].metadata.name }' )
esopspod=${esopspod:-$espod}

LOG_ADMIN_USER=${LOG_ADMIN_USER:-admin}
LOG_ADMIN_PW=${LOG_ADMIN_PW:-admin}

if oc get users "$LOG_ADMIN_USER" > /dev/null 2>&1 ; then
    os::log::debug Using existing user $LOG_ADMIN_USER
else
    os::log::info Creating cluster-admin user $LOG_ADMIN_USER
    current_project="$( oc project -q )"
    os::log::debug "$( oc login --username=$LOG_ADMIN_USER --password=$LOG_ADMIN_PW )"
    os::log::debug "$( oc login --username=system:admin )"
    os::log::debug "$( oadm policy add-cluster-role-to-user cluster-admin $LOG_ADMIN_USER )"
    os::log::debug "$( oc project $current_project )"
fi

function cleanup() {
    set +e
    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
}

trap cleanup EXIT

# test error conditions
for pod in $espod $esopspod ; do
    os::cmd::expect_failure_and_text "oc exec $pod -- es_load_kibana_ui_objects" "Usage:"
    os::cmd::expect_failure_and_text "oc exec $pod -- es_load_kibana_ui_objects no-such-user" "Could not find kibana index"
done

# use admin user created in logging framework
# make sure admin kibana index exists - log in to ES as admin user
get_test_user_token $LOG_ADMIN_USER $LOG_ADMIN_PW
for pod in $espod $esopspod ; do
    curl_es_with_token $pod "/" "$test_name" "$test_token" | curl_output
    # add the ui objects
    os::cmd::expect_success_and_text "oc exec $pod -- es_load_kibana_ui_objects $LOG_ADMIN_USER" "Success"
done

os::log::info Finished with test - login to kibana and kibana-ops to verify the admin user can load and view the dashboards with no errors
