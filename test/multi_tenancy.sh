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
current_dir=$(dirname "${BASH_SOURCE[0]}" )
repo_dir=${repodir:-"$current_dir/../"}
test_name=$(basename $0)
trap os::test::junit::reconcile_output EXIT
os::util::environment::use_sudo

os::test::junit::declare_suite_start "test/multi_tenancy"

LOGGING_PROJECT=${LOGGING_NS:-openshift-logging}
PROJECTS="multi-tenancy-1 multi-tenancy-2 multi-tenancy-3 multi-tenancy-4"

delete_users=""
cleanup_msearch_access=""

function cleanup() {
    local return_code="$?"
    cleanup_es
    set +e
	if [ "${DO_CLEANUP:-true}" == "true" ] ; then
		mkdir -p $ARTIFACT_DIR/$test_name
		oc -n $LOGGING_NS get configmap elasticsearch -o jsonpath={.data} --ignore-not-found > $ARTIFACT_DIR/$test_name/elasticsearch-configmap.log ||:
		get_all_logging_pod_logs $ARTIFACT_DIR/$test_name

		os::log::info "Removing test namespaces...."
		oc delete ns/openshift-logging ns/openshift-operators-redhat --force --grace-period=0
		for item in "ns/openshift-logging" "ns/openshift-operators-redhat"; do
			os::cmd::try_until_failure "oc get ${item}" "$((1 * $minute))"
		done
	fi
    exit $return_code
}

# useful for local testing, just cleanup the ES instance.
function cleanup_es() {
    set +e
    os::log::info "Performing ES cleanup..."
    for user in $delete_users ; do
        oc delete user $user 2>&1 | artifact_out
    done
    if [ -n "${espod:-}" ] ; then
        oc -n $LOGGING_NS logs -c elasticsearch $espod > $ARTIFACT_DIR/es.log
        oc -n $LOGGING_NS exec -c elasticsearch $espod -- logs >> $ARTIFACT_DIR/es.log
        curl_es_pod $espod /logs-app-* -XDELETE 2>&1 | artifact_out
    fi
    for proj in $PROJECTS ; do
        oc delete project $proj 2>&1 | artifact_out
        os::cmd::try_until_failure "oc get project $proj" 2>&1 | artifact_out
    done
    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output
}

trap cleanup EXIT
# enable for local testing
#trap cleanup_es EXIT

if [ "${DO_SETUP:-true}" == "true" ] ; then
	os::log::info "Deploying cluster logging..."
	${repo_dir}/hack/deploy-logging.sh
fi
espod=$( get_es_pod es )
esopspod=$( get_es_pod es-ops )
esopspod=${esopspod:-$espod}

function create_user_and_assign_to_projects() {
    local current_project; current_project="$( oc project -q )"
    local user=$1; shift
    local pw=$1; shift
    if oc get users $user > /dev/null 2>&1 ; then
        os::log::info Using existing user $user
    else
        os::log::info Creating user $user with password $pw
        create_users $user $pw false 2>&1 | artifact_out
        delete_users="$delete_users $user"
    fi
    os::log::debug "$( oc login --username=system:admin 2>&1 )"
    os::log::info Assigning $user to projects "$@"
    while [ -n "${1:-}" ] ; do
        oc project $1 2>&1 | artifact_out
        oc adm policy add-role-to-user view $user 2>&1 | artifact_out
        shift
    done
    oc project "${current_project}" > /dev/null
}

function add_message_to_index() {

    local namespace=$1
    local index="logs-app-00001"
    local pod=$2
    local aliasname=$3

    local xff="-H X-Forwarded-For:127.0.0.1"
    local xocpns='-H X-Ocp-Namespace:'"$namespace"
    local contenttype="-H Content-Type:application/json"

    local payload="{\"log\":\"log message 1\",\"stream\":\"stderr\",\"time\":\"2014-09-25T21:15:03.499185026Z\",\"kubernetes\":{\"namespace_name\":\"$namespace\",\"pod_name\":\"synthetic-logger-0.25lps-pod\"},\"docker\":{\"container_id\":\"container123\"}}"
    local alias="{\"actions\":[{\"add\":{\"index\":\"$index\",\"alias\":\"$aliasname\"}}]}"

    # add index
    os::log::info $( curl_es_pod "$pod" "/$index/_doc/" -XPOST $xff $xocpns $contenttype -d "$payload" | python -mjson.tool 2>&1 )
    # add alias
    os::log::info $( curl_es_pod "$pod" "/_aliases" -XPOST $xff $xocpns $contenttype -d "$alias" | python -mjson.tool 2>&1 )
    
    os::log::info $( curl_es_pod "$pod" "/$aliasname/_doc/_search" -XGET | python -mjson.tool 2>&1 )
}

## This function tests access to ES index/alias from kibana pod.
function test_user_has_proper_access() {
    local user=$1; shift
    local pw=$1; shift
    local alias=$1; shift

    local kpod=$( get_running_pod kibana )
    local eshost=$( get_es_svc es )

    os::log::info See if user $user can read alias /$alias
    get_test_user_token $user $pw false
    
    nrecs=$( curl_es_from_kibana $kpod $eshost "/$alias/_count" $test_token -XGET | get_count_from_json )
    expected=${1:-$user_project_num}
    if ! os::cmd::expect_success "test $nrecs = $expected" ; then
        os::log::error $user cannot access alias /$alias
        curl_es_from_kibana $kpod $eshost "/$alias/_count" $test_token -XGET | python -mjson.tool
        exit 1
    fi

    # test user has access for msearch for multiple indices
    os::log::info See if user $user can _msearch alias "/$alias"
    nrecs=$( { \
              echo '{"index":'\"${alias}\"'}'; \
              echo '{"size":0,"query":{"match_all":{}}}'; \
             } | \
             curl_es_pod_from_kibana_with_token_and_input $kpod $eshost "/_msearch" $test_token -XGET --data-binary @- | \
             get_count_from_json_from_search )
    expected=${1:-$user_project_num}
    if ! os::cmd::expect_success "test $nrecs = $expected" ; then
        os::log::error $user cannot access "/$alias" indices with _msearch
        {
            echo '{"index":'\"${alias}\"'}';
            echo '{"size":0,"query":{"match_all" : {}}}';
        } | curl_es_pod_from_kibana_with_token_and_input $kpod $eshost "/_msearch" $test_token -XGET --data-binary @- 
        exit 1
    fi

    # verify normal user has no access to .operations
    os::log::info See if user $user is denied /.operations.*
    get_test_user_token $user $pw false
    nrecs=$( curl_es_pod_from_kibana_with_token $kpod $eshost "/.operations.*/_count" $test_token -XPOST | \
                 get_count_from_json )
    if ! os::cmd::expect_success "test $nrecs = 0" ; then
        os::log::error $LOG_NORMAL_USER has improper access to .operations.* indices
        curl_es_pod_from_kibana_with_token $kpod $eshost "/.operations.*/_count" $test_token -XPOST | python -mjson.tool
        exit 1
    fi
}

curl_es_pod $espod /logs-app* -XDELETE | artifact_out

for proj in multi-tenancy-1 multi-tenancy-2 multi-tenancy-3 ; do
    os::log::info Creating project $proj
    oc adm new-project $proj --node-selector='' 2>&1 | artifact_out
    os::cmd::try_until_success "oc get project $proj" 2>&1 | artifact_out
    os::log::info Creating test index and entry for $proj
    add_message_to_index $proj $espod logs-app
done
os::log::info Creating project multi-tenancy-4 2>&1 | artifact_out
oc adm new-project multi-tenancy-4 --node-selector='' 2>&1 | artifact_out
os::cmd::try_until_success "oc get project multi-tenancy-4" 2>&1 | artifact_out

# if you ever want to run this test again on the same machine, you'll need to
# use different usernames, otherwise you'll get this odd error:
# # oc login --username=loguser --password=loguser
# error: The server was unable to respond - verify you have provided the correct host and port and that the server is currently running.
LOG_NORMAL_USER1=${LOG_NORMAL_USER1:-loguser1-$RANDOM}
LOG_NORMAL_USER1_PW=${LOG_NORMAL_USER1_PW:-loguser1-$RANDOM}

LOG_NORMAL_USER2=${LOG_NORMAL_USER2:-loguser2-$RANDOM}
LOG_NORMAL_USER2_PW=${LOG_NORMAL_USER2_PW:-loguser2-$RANDOM}

LOG_NORMAL_USER3=${LOG_NORMAL_USER3:-loguser3-$RANDOM}
LOG_NORMAL_USER3_PW=${LOG_NORMAL_USER3_PW:-loguser3-$RANDOM}

LOG_NORMAL_USER4=${LOG_NORMAL_USER4:-loguser4-$RANDOM}
LOG_NORMAL_USER4_PW=${LOG_NORMAL_USER4_PW:-loguser4-$RANDOM}

create_users $LOG_NORMAL_USER1 $LOG_NORMAL_USER1_PW false \
             $LOG_NORMAL_USER2 $LOG_NORMAL_USER2_PW false \
             $LOG_NORMAL_USER3 $LOG_NORMAL_USER3_PW false \
             $LOG_NORMAL_USER4 $LOG_NORMAL_USER4_PW false 2>&1 | artifact_out

delete_users="$LOG_NORMAL_USER1 $LOG_NORMAL_USER2 $LOG_NORMAL_USER3 $LOG_NORMAL_USER4"

create_user_and_assign_to_projects $LOG_NORMAL_USER1 $LOG_NORMAL_USER1_PW multi-tenancy-1 multi-tenancy-2
create_user_and_assign_to_projects $LOG_NORMAL_USER2 $LOG_NORMAL_USER2_PW multi-tenancy-1 
create_user_and_assign_to_projects $LOG_NORMAL_USER4 $LOG_NORMAL_USER4_PW multi-tenancy-4 

oc login --username=system:admin > /dev/null
oc project $LOGGING_PROJECT > /dev/null

# loguser1 has access to two documents
test_user_has_proper_access $LOG_NORMAL_USER1 $LOG_NORMAL_USER1_PW logs-app
# loguser2 has access to one document
test_user_has_proper_access $LOG_NORMAL_USER2 $LOG_NORMAL_USER2_PW logs-app
# loguser3 has access to no ducuments as user has access to no projects
test_user_has_proper_access $LOG_NORMAL_USER3 $LOG_NORMAL_USER3_PW logs-app
# loguser4 has access to no documents as there are no documents matching the project
test_user_has_proper_access $LOG_NORMAL_USER4 $LOG_NORMAL_USER4_PW logs-app 0
