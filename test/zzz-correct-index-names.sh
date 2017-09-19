#!/bin/bash

# This is a test suite for correct index naming
# This test should be run last in the test suite with a
# well populated elasticsearch containing both indices from
# the tests as well as indices from openshift and system logs

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::util::environment::use_sudo

os::test::junit::declare_suite_start "test/zzz-correct-index-names"

# ensure that _default_, _openshift_, and _openshift-infra_ indices
# are not present in es

# ensure that _default_, _openshift_, and _openshift-infra_ namespace
# records are not present in es

# ensure that _default_, _openshift_, and _openshift-infra_ namespace
# records are present in es-ops

es_pod=$( get_es_pod es )
es_ops_pod=$( get_es_pod es-ops )
es_ops_pod=${es_ops_pod:-$es_pod}

for project in default openshift openshift-infra ; do
    qs='{"query":{"term":{"kubernetes.namespace_name":"'"${project}"'"}}}'
    os::cmd::expect_success_and_not_text "curl_es $es_pod /_cat/indices" "project.${project}."
    os::cmd::expect_success_and_text "curl_es $es_pod /project.${project}.*/_count | get_count_from_json" "^0\$"
    os::cmd::expect_success_and_text "curl_es $es_pod /project.*/_count -X POST -d '$qs' | get_count_from_json" "^0\$"
    if [ "$es_pod" != "$es_ops_pod" ] ; then
        os::cmd::expect_success_and_not_text "curl_es $es_ops_pod /_cat/indices" "project.${project}."
        os::cmd::expect_success_and_text "curl_es $es_ops_pod /project.${project}.*/_count | get_count_from_json" "^0\$"
        os::cmd::expect_success_and_text "curl_es $es_ops_pod /project.*/_count -X POST -d '$qs' | get_count_from_json" "^0\$"
    fi
    # there will almost always be logs from the default namespace from router and registry
    # there will almost never be logs from openshift and openshift-infra
    if [ "$project" = "default" ] ; then
        os::cmd::expect_success_and_not_text "curl_es $es_ops_pod /.operations.*/_count -X POST -d '$qs' | get_count_from_json" "^0\$"
    fi
done
