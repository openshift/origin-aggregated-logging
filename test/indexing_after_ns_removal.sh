#!/bin/bash

# This is a test suite for checking the index mapping after the project has
# been deleted and another namespaces has been created with the same name. 

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::test::junit::declare_suite_start "test/indexing_after_ns_removal"


create_pod(){
# keep indentation clean
    oc create -f - <<EOF &>/dev/null
apiVersion: v1
kind: Pod
metadata:
  name: bar
  namespace: $NS
spec:
  containers:
  - image: gcr.io/google_containers/busybox:latest
    name: bar
    command: [ "/bin/sh", "-c", "echo foo-bar $1" ]
  restartPolicy: Never
EOF
}


cleanup(){
    local return_code="$?"

    # delete all the $NS indices
    curl_es $es_pod /project.$NS.* -XDELETE || :

    # remove temp files used to store uid data
    rm -f temp_ns_uid temp_pod_uid 

    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output

    exit $return_code
}
trap "cleanup" EXIT


NS="pelle-foo"
es_pod=$( get_es_pod es )

# Create a namespace named pelle-foo containing a pod, which logs a line and
# then remove the namespace, repeating this procedure 20 times
for i in $( seq 1 20 ); 
do
    oc create namespace $NS &>/dev/null

    # wait till the project get created
    while ! oc get namespace $NS &>/dev/null; do sleep 1; done

    os::log::info Creating project $NS with UID $(oc get namespace $NS -o jsonpath={.metadata.uid})
    create_pod $i
    # wait till the pod get created
    while ! oc get pod bar -n $NS &>/dev/null; do sleep 1; done
    sleep 5s
    os::log::info Creating pod bar with UID $(oc get pod -n $NS -o jsonpath={.metadata.uid})

    # store UID for both NS and pod
    oc get namespace $NS -o jsonpath={.metadata.uid}  >> temp_ns_uid && echo "" >> temp_ns_uid
    oc get pod bar -n $NS -o jsonpath={.metadata.uid}  >> temp_pod_uid && echo "" >> temp_pod_uid

    # delete NS
    oc delete namespace $NS &>/dev/null
    while oc get namespace $NS &>/dev/null; do sleep 1; done
done

# Dump indices to artifact_out before ending the test
curl_es $es_pod /_cat/indices 2>&1 | artifact_out

# Test indexing, if the amount of indices created is other than 20, exit with 1:
amount_of_idx=$(curl_es $es_pod /_cat/indices?h=index,docs.count | grep pelle | wc -l)

if [ $amount_of_idx -ne 20 ]
then  
    os::log::error Amount of indices created is $amount_of_idx which is less than the amount of projects created
    exit 1
fi

## example of wrong indexing:
# oc rsh -c elasticsearch $es_pod es_util  --query=_cat/indices?h=index,docs.count | grep pelle 

# project.pelle-foo.53a8d3e3-42f7-11e8-a037-fa163e2c1fb0.2018.04.18                 3 
# project.pelle-foo.5b71ac2c-42f7-11e8-a037-fa163e2c1fb0.2018.04.18                13 
# project.pelle-foo.6b04cc03-42f7-11e8-a037-fa163e2c1fb0.2018.04.18                 4

# verify that the kubernetes metadata in the record matches the object data
# stored in temp_ns_uid and temp_pod_uid files
# Note: If we reach this point, means there are 20 indices with one document
# each, so no need to iterate through documents within an index but only over
# the indices.

for index in $(curl_es $es_pod /_cat/indices?h=index | grep pelle-foo)
do
    namespace_uid=$(curl_es $es_pod /"${index}"/_search?q=kubernetes.namespace_id:* | jq . | grep -i namespace_id | awk -F'"' '{ print $4 }')
    grep -m 1 "${namespace_uid}" temp_ns_uid &>/dev/null
    [ "$?" != "0" ] && os::log::error ${namespace_uid} does not match any UID collected from the actual namespace list during namespace creation

    pod_uid=$(curl_es $es_pod /"${index}"/_search?q=kubernetes.namespace_id:* | jq . | grep -i pod_id | awk -F'"' '{ print $4 }')
    grep -m 1 "${pod_uid}" temp_ns_uid &>/dev/null
    [ "$?" != "0" ] && os::log::error ${pod_id} does not match any UID collected from the actual pod list during pod creation
done


# .orphaned index  is not created by default, so if it exists, then it contains records
[[ $(curl_es $es_pod /_cat/indices?h=index,docs.count | grep .orphaned) ]] && os::log::error  There are records in the .orphaned index.
