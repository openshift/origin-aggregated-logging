#!/bin/bash
# this grants the given user access to _msearch on the given projects
# the /sg/roles/0 should look like this:
#         "hack_for_user_access_loguser": {
#             "cluster": [],
#             "indices": {
#                 "multi-tenancy-1?843a78a0-5ad5-11e7-b47f-0e35fd64a858?*": {
#                     "*": [
#                         "indices:admin/validate/query*",
#                         "indices:admin/get*",
#                         "indices:admin/mappings/fields/get*",
#                         "indices:data/read*"
#                     ]
#                 },
#                 "multi-tenancy-2?84f15332-5ad5-11e7-b47f-0e35fd64a858?*": {
#                     "*": [
#                         "indices:admin/validate/query*",
#                         "indices:admin/get*",
#                         "indices:admin/mappings/fields/get*",
#                         "indices:data/read*"
#                     ]
#                 },
#                 "project?multi-tenancy-1?843a78a0-5ad5-11e7-b47f-0e35fd64a858?*": {
#                     "*": [
#                         "indices:admin/validate/query*",
#                         "indices:admin/get*",
#                         "indices:admin/mappings/fields/get*",
#                         "indices:data/read*"
#                     ]
#                 },
#                 "project?multi-tenancy-2?84f15332-5ad5-11e7-b47f-0e35fd64a858?*": {
#                     "*": [
#                         "indices:admin/validate/query*",
#                         "indices:admin/get*",
#                         "indices:admin/mappings/fields/get*",
#                         "indices:data/read*"
#                     ]
#                 }
#             }
#         }

set -euo pipefail

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

LOGGING_PROJECT=${LOGGING_PROJECT:-logging}

# $1 - es pod name
# $2 - es endpoint
# rest - any args to pass to curl
function curl_es() {
    local pod="$1"
    local endpoint="$2"
    shift; shift
    local args=( "${@:-}" )

    local secret_dir="/etc/elasticsearch/secret/"
    oc exec -n $LOGGING_PROJECT "${pod}" -- \
       curl --silent --insecure "${args[@]}" \
       --key "${secret_dir}admin-key"   \
       --cert "${secret_dir}admin-cert" \
       "https://localhost:9200${endpoint}"
}

# $1 - es pod name
# $2 - es endpoint
# rest - any args to pass to curl
function curl_es_input() {
    local pod="$1"
    local endpoint="$2"
    shift; shift
    local args=( "${@:-}" )

    local secret_dir="/etc/elasticsearch/secret/"
    oc exec -i "${pod}" -n $LOGGING_PROJECT -- \
       curl --silent --insecure "${args[@]}" \
       --key "${secret_dir}admin-key"   \
       --cert "${secret_dir}admin-cert" \
       "https://localhost:9200${endpoint}"
}

usage() {
    echo Usage: $0 user-name [project-1 ... project-N]
    echo  or
    echo Usage: $0 user-name --all
    echo If no projects are specified, the msearch access will be removed.
    echo If --all is specified, look up and use all of the projects that
    echo the user has access to.
    echo This script assumes the logging components are in the namespace
    echo   $LOGGING_PROJECT.  Set the environment variable
    echo   LOGGING_PROJECT=project-name if the Elasticsearch pods are running
    echo   in a different namespace.
}

if [ -z "${1:-}" ] ; then
    usage
    exit 1
fi

if oc get users "$1" > /dev/null 2>&1 ; then
    echo Using user "$1" . . .
else
    echo Error: user "$1" not found
    usage
    exit 1
fi

user="$1" ; shift

if [ "x${1:-}" = "x--all" ] ; then
    echo Finding all projects that user "$user" has access to . . .
    set -- $( oc get --as="$user" projects -o jsonpath='{.items[*].metadata.name}' )
fi

for proj in "$@" ; do
    if oc get project "$proj"  > /dev/null 2>&1 ; then
        # make sure user has log access to project
        hasaccess=$( oc policy can-i -n "$proj" get pods/log --user="$user" )
        if [ "$hasaccess" = yes ] ; then
            echo User "$user" has access to project "$proj"
        else
            echo Error: user "$user" does not have access to view logs in project "$proj"
            exit 1
        fi
    else
        echo Error: project "$proj" not found
        usage
        exit 1
    fi
done

if [ "$#" -gt 0 ] ; then
    uuids=$( oc get project "$@" -o jsonpath='{.items[*].metadata.uid}' )
    if [ -z "$uuids" ] ; then
        echo Error: could not get the project uuids for the given projects "$@"
        exit 1
    fi
fi

espod=$( oc get -n $LOGGING_PROJECT pods --selector component=es -o jsonpath='{ .items[0].metadata.name }' )

if [ -z "$espod" ] ; then
    echo Error: no Elasticsearch pods found in project \'$LOGGING_PROJECT\'
    exit 1
fi

role_name="multi_index_access_for_user_$user"

config_index_name=$( oc exec -c elasticsearch -n $LOGGING_PROJECT $espod -- python -c "import yaml; print yaml.load(open('/usr/share/java/elasticsearch/config/elasticsearch.yml'))['searchguard']['config_index_name']" )
if [ -z "$config_index_name" ] ; then
    echo Error: could not extract the searchguard index name from $espod /usr/share/java/elasticsearch/config/elasticsearch.yml
    exit 1
fi

sg_index=$( oc exec -c elasticsearch -n $LOGGING_PROJECT $espod -- bash -c "eval 'echo $config_index_name'" )
if [ -z "$sg_index" ] ; then
    echo Error: could not convert "$config_index_name" in $espod to the searchguard index name
    exit 1
fi

echo Input looks good - fixing ACLs . . .

curl_es $espod /$sg_index/roles/0 | PROJECTS="$@" UUIDS="${uuids:-}" python -c '
import json
import sys
import os
role_name = "'"$role_name"'"
projects = os.environ["PROJECTS"].split()
uuids = os.environ["UUIDS"].split()
perm = ["indices:admin/validate/query*", "indices:admin/get*", "indices:admin/mappings/fields/get*", "indices:data/read*"]
hsh = json.load(sys.stdin)["_source"]
if not projects:
    if role_name in hsh:
        del hsh[role_name]
else:
    hsh[role_name] = {"cluster":[],"indices":{}}
    for proj,uuid in zip(projects,uuids):
        pat1 = "{}?{}?*".format(proj, uuid)
        pat2 = "project?{}?{}?*".format(proj, uuid)
        hsh[role_name]["indices"][pat1] = {"*": perm}
        hsh[role_name]["indices"][pat2] = {"*": perm}
json.dump(hsh, sys.stdout)
' | curl_es_input $espod /$sg_index/roles/0 -XPUT -d@- | \
        curl_output

curl_es $espod /$sg_index/rolesmapping/0 | PROJECTS="$@" python -c '
import json
import sys
import os
role_name = "'"$role_name"'"
user_name = "'"$user"'"
projects = os.environ["PROJECTS"].split()
hsh = json.load(sys.stdin)["_source"]
if not projects:
    if role_name in hsh:
        del hsh[role_name]
else:
    hsh[role_name] = {"users":[user_name]}
json.dump(hsh, sys.stdout)
' | curl_es_input $espod /$sg_index/rolesmapping/0 -XPUT -d@- | \
        curl_output

echo . . . Done
