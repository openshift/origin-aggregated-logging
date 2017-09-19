#!/bin/bash

# Test various aspects of multi tenancy
# Test that regular users can view indices of
# projects they are members of
# Test that regular users cannot view indices
# of projects they are not members of
# Test multi-project searches e.g.
# {"index":["project.a.*","project.b.*"]}
# {"query" : {"match_all" : {}}}
# cat msearch.json | curl https://localhost:9200/_msearch -XPOST --data-binary @-
source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
trap os::test::junit::reconcile_output EXIT
os::util::environment::use_sudo

os::test::junit::declare_suite_start "test/multi_tenancy"

espod=$( get_es_pod es )
esopspod=$( get_es_pod es-ops )
esopspod=${esopspod:-$espod}

# HACK HACK HACK
# remove this once we have real multi-tenancy, multi-index support
function hack_msearch_access() {
    LOGGING_PROJECT=logging ${OS_O_A_L_DIR}/hack/enable-kibana-msearch-access.sh "$@"
}

delete_users=""
cleanup_msearch_access=""

function cleanup() {
    set +e
    for user in $cleanup_msearch_access ; do
        hack_msearch_access $user
    done
    for user in $delete_users ; do
        oc delete user $user
    done
    if [ -n "${espod:-}" ] ; then
        curl_es $espod /project.multi-tenancy-* -XDELETE > /dev/null
    fi
    for proj in multi-tenancy-1 multi-tenancy-2 multi-tenancy-3 ; do
        oc delete project $proj
    done
    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
}

trap cleanup EXIT

function create_user_and_assign_to_projects() {
    local current_project; current_project="$( oc project -q )"
    local user=$1; shift
    local pw=$1; shift
    if oc get users $user > /dev/null 2>&1 ; then
        os::log::info Using existing user $user
    else
        os::log::info Creating user $user with password $pw
        os::log::debug "$( oc login --username=$user --password=$pw 2>&1 )"
        delete_users="$delete_users $user"
    fi
    os::log::debug "$( oc login --username=system:admin 2>&1 )"
    os::log::info Assigning user to projects "$@"
    while [ -n "${1:-}" ] ; do
        os::log::debug "$( oc project $1 2>&1 )"
        os::log::debug "$( oadm policy add-role-to-user view $user 2>&1 )"
        shift
    done
    oc project "${current_project}" > /dev/null
}

function add_message_to_index() {
    # project is $1
    # message is $2
    # espod is $3
    local project_uuid=$( oc get project $1 -o jsonpath='{ .metadata.uid }' )
    local index="project.$1.$project_uuid.$(date -u +'%Y.%m.%d')"
    os::log::debug $( curl_es "$3" "/$index/multi-tenancy-test/" -XPOST -d '{"message":"'${2:-"multi-tenancy message"}'"}' | python -mjson.tool 2>&1 )
}

function test_user_has_proper_access() {
    local user=$1; shift
    local pw=$1; shift
    local indices="["
    local comma=""
    # rest - indices to which access should be granted
    for proj in "$@" ; do
        os::log::info See if user $user can read /project.$proj.*
        get_test_user_token $user $pw
        nrecs=$( curl_es_with_token $espod "/project.$proj.*/_count" $test_name $test_token | \
                     get_count_from_json )
        if ! os::cmd::expect_success "test $nrecs = 1" ; then
            os::log::error $user cannot access project.$proj.* indices
            curl_es_with_token $espod "/project.$proj.*/_count" $test_name $test_token | python -mjson.tool
            exit 1
        fi
        indices="${indices}${comma}"'"'"project.$proj.*"'"'
        comma=,
    done
    indices="${indices}]"

    # test user has access for msearch for multiple indices
    os::log::info See if user $user can _msearch "$indices"
    get_test_user_token $user $pw
    nrecs=$( { echo '{"index":'"${indices}"'}'; echo '{"size":0,"query":{"match_all":{}}}'; } | \
                     curl_es_with_token_and_input $espod "/_msearch" $test_name $test_token -XPOST --data-binary @- | \
                     get_count_from_json_from_search )
    if ! os::cmd::expect_success "test $nrecs = 2" ; then
        os::log::error $user cannot access "$indices" indices with _msearch
        {
            echo '{"index":'"${indices}"'}'
            echo '{"query" : {"match_all" : {}}}'
        } | curl_es_with_token_and_input $espod "/_msearch" $test_name $test_token -XPOST --data-binary @- | \
            python -mjson.tool
        exit 1
    fi

    # verify normal user has no access to default indices
    os::log::info See if user $user is denied /project.default.*
    get_test_user_token $user $pw
    nrecs=$( curl_es_with_token $espod "/project.default.*/_count" $test_name $test_token | \
                 get_count_from_json )
    if ! os::cmd::expect_success "test $nrecs = 0" ; then
        os::log::error $LOG_NORMAL_USER has improper access to project.default.* indices
        curl_es_with_token $espod "/project.default.*/_count" $test_name $test_token | python -mjson.tool
        exit 1
    fi

    # verify normal user has no access to .operations
    os::log::info See if user $user is denied /.operations.*
    get_test_user_token $user $pw
    nrecs=$( curl_es_with_token $esopspod "/.operations.*/_count" $test_name $test_token | \
                 get_count_from_json )
    if ! os::cmd::expect_success "test $nrecs = 0" ; then
        os::log::error $LOG_NORMAL_USER has improper access to .operations.* indices
        curl_es_with_token $esopspod "/.operations.*/_count" $test_name $test_token | python -mjson.tool
        exit 1
    fi
}

curl_es $espod /project.multi-tenancy-* -XDELETE > /dev/null

for proj in multi-tenancy-1 multi-tenancy-2 multi-tenancy-3 ; do
    os::log::info Creating project $proj
    os::log::debug "$( oadm new-project $proj --node-selector='' 2>&1 )"
    os::log::info Creating test index and entry for $proj
    add_message_to_index $proj "" $espod
done

# if you ever want to run this test again on the same machine, you'll need to
# use different usernames, otherwise you'll get this odd error:
# # oc login --username=loguser --password=loguser
# error: The server was unable to respond - verify you have provided the correct host and port and that the server is currently running.
LOG_NORMAL_USER=${LOG_NORMAL_USER:-loguser}
LOG_NORMAL_PW=${LOG_NORMAL_PW:-loguser}

LOG_USER2=${LOG_USER2:-loguser2}
LOG_PW2=${LOG_PW2:-loguser2}

create_user_and_assign_to_projects $LOG_NORMAL_USER $LOG_NORMAL_PW multi-tenancy-1 multi-tenancy-2
create_user_and_assign_to_projects $LOG_USER2 $LOG_PW2 multi-tenancy-2 multi-tenancy-3

# test failure
os::cmd::expect_failure_and_text "hack_msearch_access" "Usage:"
os::cmd::expect_failure_and_text "hack_msearch_access no-such-user no-such-project" "user no-such-user not found"
os::cmd::expect_failure_and_text "hack_msearch_access $LOG_NORMAL_USER no-such-project" "project no-such-project not found"
os::cmd::expect_failure_and_text "hack_msearch_access $LOG_NORMAL_USER default" "$LOG_NORMAL_USER does not have access to view logs in project default"

os::cmd::expect_success "hack_msearch_access $LOG_NORMAL_USER multi-tenancy-1 multi-tenancy-2"
cleanup_msearch_access="$cleanup_msearch_access $LOG_NORMAL_USER"
os::cmd::expect_success "hack_msearch_access $LOG_USER2 --all"
cleanup_msearch_access="$cleanup_msearch_access $LOG_USER2"

oc login --username=system:admin > /dev/null
oc project logging > /dev/null

test_user_has_proper_access $LOG_NORMAL_USER $LOG_NORMAL_PW multi-tenancy-1 multi-tenancy-2
test_user_has_proper_access $LOG_USER2 $LOG_PW2 multi-tenancy-2 multi-tenancy-3
