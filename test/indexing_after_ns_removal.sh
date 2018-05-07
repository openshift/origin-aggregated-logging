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

    for index in $(oc rsh -c elasticsearch $es_pod es_util  --query=_cat/indices?h=index,docs.count | grep pelle | awk '{ print $1 }')
    do 
        oc exec -c elasticsearch $es_pod -- curl --key /etc/elasticsearch/secret/admin-key   --cert /etc/elasticsearch/secret/admin-cert   --cacert /etc/elasticsearch/secret/admin-ca -XDELETE   "https://localhost:9200/$index"
    done
    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output

    exit $return_code
}
trap "cleanup" EXIT


NS="pelle-foo"
espod=$( get_es_pod es )

# Create a namespace named pelle-foo containing a pod, which logs a line and
# then remove the namespace, repeating this procedure 20 times
for i in $( seq 1 20 ); 
do
    oc create namespace $NS &>/dev/null
    # wait till the project get created
    while ! oc get namespace $NS &>/dev/null; do sleep 1; done

    os::log::info Creating project  $(oc get namespace $NS -o jsonpath={.metadata.uid})
    create_pod $i
    # wait till the pod get created
    while ! oc get pod bar -n $NS &>/dev/null; do sleep 1; done
    sleep 5s
    oc delete namespace $NS &>/dev/null
    while oc get namespace $NS &>/dev/null; do sleep 1; done
done

# Test indexing, if the amount of indices created other than 20, return with 1:
amount_of_idx=$(oc rsh -c elasticsearch $espod es_util  --query=_cat/indices?h=index,docs.count | grep pelle | wc -l)
if [ $amount_of_idx -ne 20 ]; then  exit 1; fi


## example of wrong indexing:
# oc rsh -c elasticsearch $espod es_util  --query=_cat/indices?h=index,docs.count | grep pelle 

# project.pelle-foo.53a8d3e3-42f7-11e8-a037-fa163e2c1fb0.2018.04.18                 3 
# project.pelle-foo.5b71ac2c-42f7-11e8-a037-fa163e2c1fb0.2018.04.18                13 
# project.pelle-foo.6b04cc03-42f7-11e8-a037-fa163e2c1fb0.2018.04.18                 4
