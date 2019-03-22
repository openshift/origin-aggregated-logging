#!/bin/bash
# this is meant to be sourced - called in the current context
# of the script as TEST_COMMAND - rather than called as a separate
# fork/exec script so that variables such as OPENSHIFT_BUILD_NAMESPACE and
# ARTIFACT_DIR will be available - see
# https://github.com/openshift/release/blob/master/ci-operator/templates/cluster-launch-installer-src.yaml
# where the script will sourced

logging_err_exit() {
    oc get deploy >> ${ARTIFACT_DIR}/logging_err_exit.log 2>&1 || :
    oc get pods >> ${ARTIFACT_DIR}/logging_err_exit.log 2>&1 || :
    oc -n openshift-operators get elasticsearch >> ${ARTIFACT_DIR}/logging_err_exit.log 2>&1 || :
    oc get clusterlogging >> ${ARTIFACT_DIR}/logging_err_exit.log 2>&1 || :
    oc get crds >> ${ARTIFACT_DIR}/logging_err_exit.log 2>&1 || :
    oc describe pods >> ${ARTIFACT_DIR}/logging_err_exit.log 2>&1 || :
    for p in $( oc get pods -o jsonpath='{.items[*].metadata.name}' ) ; do
        for container in $( oc get po $p -o jsonpath='{.spec.containers[*].name}' ) ; do
            echo pod $p container $container >> ${ARTIFACT_DIR}/logging_err_exit.log 2>&1 || :
            oc logs -c $container $p >> ${ARTIFACT_DIR}/logging_err_exit.log 2>&1 || :
        done
    done
    oc get events >> ${ARTIFACT_DIR}/logging_err_exit.log 2>&1 || :
    cat ${ARTIFACT_DIR}/test_output
    exit 1
}

wait_for_condition()
{
    # $1 is shell function condition to execute until it returns success
    # $2 is the timeout number of retries - default 60
    # $3 is the interval in seconds - default 1
    # e.g. the total timeout in seconds is timeout * interval
    local cmd=$1
    local timeout=${2:-60}
    local interval=${3:-1}
    local ii=0
    for ii in $( seq 1 $timeout ) ; do
        if $cmd ; then
            break
        fi
        sleep $interval
    done
    if [ $ii = $timeout ] ; then
        return 1
    fi
    return 0
}

TEST_OBJ_DIR=${TEST_OBJ_DIR:-openshift/ci-operator/build-image}

# Create the openshift-logging namespace:
oc create -f $TEST_OBJ_DIR/openshift-logging-namespace.yaml
oc get projects | grep logging || :

# Create an OperatorGroup for openshift-logging:
oc -n openshift-logging create -f $TEST_OBJ_DIR/openshift-logging-operatorgroup.yaml

# Create the CatalogSourceConfig for the elasticsearch-operator in the namespace openshift-marketplace:
oc create -n openshift-marketplace -f $TEST_OBJ_DIR/elasticsearch-catalogsourceconfig.yaml
oc get -n openshift-marketplace CatalogSourceConfig | grep elasticsearch || :

# Create the subscription for elasticsearch in the namespace openshift-operators:
oc create -n openshift-operators -f $TEST_OBJ_DIR/elasticsearch-subscription.yaml
oc get -n openshift-operators subscriptions | grep elaasticsearch || :

# Create the CatalogSourceConfig for cluster-logging in the namespace openshift-marketplace:
oc create -n openshift-marketplace -f $TEST_OBJ_DIR/cluster-logging-catalogsourceconfig.yaml
oc get -n openshift-marketplace CatalogSourceConfig | grep logging || :

# create the subscription in the namespace openshift-logging:
oc create -n openshift-logging -f $TEST_OBJ_DIR/cluster-logging-subscription.yaml
oc get -n openshift-logging subscriptions | grep logging || :

# at this point, the cluster-logging-operator should be deployed in the
# openshift-logging namespace
oc project openshift-logging

DEFAULT_TIMEOUT=${DEFAULT_TIMEOUT:-600}
wait_func() {
    oc -n openshift-operators get pods 2> /dev/null | grep -q 'elasticsearch-operator.*Running' && \
    oc get pods 2> /dev/null | grep -q 'cluster-logging-operator.*Running'
}
if ! wait_for_condition wait_func $DEFAULT_TIMEOUT > ${ARTIFACT_DIR}/test_output 2>&1 ; then
    echo ERROR: one of or both of elasticsearch-operator and cluster-logging-operator pod not running
    logging_err_exit
fi

# get the OLM pod
olmpod=$( oc -n openshift-operator-lifecycle-manager get pods | awk '/^olm-operator-.* Running / {print $1}' )

# disable the OLM so that we can change images in the cluster-logging-operator
oc -n openshift-operator-lifecycle-manager scale --replicas=0 deploy/olm-operator

wait_func() {
    oc -n openshift-operator-lifecycle-manager get pod $olmpod > /dev/null 2>&1
}
if ! wait_for_condition wait_func $DEFAULT_TIMEOUT > ${ARTIFACT_DIR}/test_output 2>&1 ; then
    echo ERROR: could not stop olm pod $olmpod
    logging_err_exit
fi

# get the clo pod
wait_func() {
    oc get pods | grep -q '^cluster-logging-operator-.* Running'
}
if ! wait_for_condition wait_func $DEFAULT_TIMEOUT > ${ARTIFACT_DIR}/test_output 2>&1 ; then
    echo ERROR: could not get cluster-logging-operator pod
    logging_err_exit
fi
clopod=$( oc get pods | awk '/^cluster-logging-operator-.* Running / {print $1}' )

# update the images to use in the CLO
if [ -n "${OPENSHIFT_BUILD_NAMESPACE:-}" -a -n "${IMAGE_FORMAT:-}" ] ; then
    # we are running in the CI environment
    # OPENSHIFT_BUILD_NAMESPACE=ci-op-xxx
    # IMAGE_FORMAT=registry.svc.ci.openshift.org/ci-op-xxx/stable:${component}
    # edit the deployments - for the logging images, use pipeline
    # for example, change this:
    # docker.io/openshift/origin-logging-elasticsearch5:latest
    # to this:
    # $imageprefix/pipeline:logging-elasticsearch5
    imageprefix=$( echo "$IMAGE_FORMAT" | sed -e 's,/stable:.*$,/,' )
    oc set env deploy/cluster-logging-operator --list | grep _IMAGE= | \
    sed -e 's,docker.io/openshift/origin-logging-\(..*\):latest,'"$imageprefix"'pipeline:logging-\1,' \
        -e 's,quay.io/openshift/origin-logging-\(..*\):latest,'"$imageprefix"'pipeline:logging-\1,' | \
    oc set env -e - deploy/cluster-logging-operator
    testimage=${imageprefix}pipeline:src
    testroot=$( pwd )
else
    # running in a dev env
    OPENSHIFT_BUILD_NAMESPACE=openshift
    registry=$( oc -n $OPENSHIFT_BUILD_NAMESPACE get is -l logging-infra=development -o jsonpath='{.items[0].status.dockerImageRepository}' | \
        sed 's,/[^/]*$,/,' )
    oc set env deploy/cluster-logging-operator --list | grep _IMAGE= | \
    sed -e '/docker.io\/openshift\/origin-logging-/ {s,docker.io/openshift/origin-,'"$registry"',}' \
        -e '/quay.io\/openshift\/origin-logging-/ {s,quay.io/openshift/origin-,'"$registry"',}' | \
    oc set env -e - deploy/cluster-logging-operator
    testimage=${registry}logging-ci-test-runner:latest
    testroot=/go/src/github.com/openshift/origin-aggregated-logging
fi

# doing the oc set env will restart clo - check to make sure it was restarted
wait_func() {
    # wait until the old clo pod is not running and a new one is
    ! oc get pods $clopod > /dev/null 2>&1 && oc get pods | grep -q '^cluster-logging-operator-.* Running'
}
if ! wait_for_condition wait_func $DEFAULT_TIMEOUT > ${ARTIFACT_DIR}/test_output 2>&1 ; then
    echo ERROR: cluster-logging-operator pod was not restarted
    logging_err_exit
fi

oc set env deploy/cluster-logging-operator --list | grep _IMAGE=

oc -n openshift-logging create -f $TEST_OBJ_DIR/cr.yaml
wait_func() {
    oc get pods 2> /dev/null | grep -q 'kibana.*Running' && \
    oc get pods 2> /dev/null | grep -v 'elasticsearch-operator' | grep -q 'elasticsearch.*Running' && \
    oc get pods 2> /dev/null | grep -q 'fluentd.*Running'
}
if ! wait_for_condition wait_func $DEFAULT_TIMEOUT > ${ARTIFACT_DIR}/test_output 2>&1 ; then
    echo ERROR: operator did not start pods after 300 seconds
    logging_err_exit
fi

# set elasticsearch to unmanaged - so that the elasticsearch-operator
# won't try to do anything to elasticsearch when we shut it down
oc patch elasticsearch elasticsearch --type=json --patch '[
        {"op":"replace","path":"/spec/managementState","value":"Unmanaged"}]'

# get the elasticsearch-operator pod
esopod=$( oc -n openshift-operators get pods | awk '/^elasticsearch-operator-.* Running / {print $1}' )

# disable the elasticsearch-operator so that we can alter elasticsearch
oc -n openshift-operators scale --replicas=0 deploy/elasticsearch-operator

wait_func() {
    oc -n openshift-operators get pod $esopod > /dev/null 2>&1
}
if ! wait_for_condition wait_func $DEFAULT_TIMEOUT > ${ARTIFACT_DIR}/test_output 2>&1 ; then
    echo ERROR: could not stop elasticsearch-operator pod $esopod
    logging_err_exit
fi

# sometimes elasticsearch get stuck in a strange state - the pod is
# running but the deployment status says paused - so kick it here
for dp in $( oc get deploy -l component=elasticsearch -o name ) ; do
    if oc get $dp -o yaml | grep -q "reason: DeploymentPaused" ; then
        oc rollout resume $dp
    fi
    # wait for oc rollout status to return success
    wait_func() {
        oc rollout status --watch=false $dp | grep -q "successfully rolled out"
    }
    if ! wait_for_condition wait_func $DEFAULT_TIMEOUT > ${ARTIFACT_DIR}/test_output 2>&1 ; then
        echo ERROR: elasticsearch deployment $dp not reporting success
        logging_err_exit
    fi
done

# the ci test pod, kibana pod, and fluentd/rsyslog pod, all have to run on the same node
kibnode=$( oc get pods -l component=kibana -o jsonpath='{.items[0].spec.nodeName}' )
oc label node $kibnode --overwrite logging-ci-test=true

# create secret for test and add $KUBECONFIG contents
oc create secret generic logging-ci-test-kubeconfig \
    --from-file=admin.kubeconfig.orig=$KUBECONFIG
# we're using the same image as what we are currently running in, just launching
# it in a pod in the remote cluster - so the pwd is the test root is the same
# there and here
if [ -n "${ARTIFACT_DIR:-}" ] ; then
    artifact_dir_arg="-p ARTIFACT_DIR=$ARTIFACT_DIR"
fi
oc process -p TEST_ROOT=$testroot \
    -p TEST_NAMESPACE_NAME=$( oc project -q ) \
    -p TEST_IMAGE=$testimage \
    ${artifact_dir_arg:-} \
    -f hack/testing/templates/logging-ci-test-runner-template.yaml | oc create -f -

wait_func() {
    oc logs logging-ci-test-runner > /dev/null 2>&1
}
if ! wait_for_condition wait_func $DEFAULT_TIMEOUT > ${ARTIFACT_DIR}/test_output 2>&1 ; then
    echo ERROR: failed to start logging-ci-test-runner after $DEFAULT_TIMEOUT seconds
    logging_err_exit
fi

# this will exit with error when the pod exits - ignore that error
oc logs -f logging-ci-test-runner 2>&1 | tee $ARTIFACT_DIR/logging-test-output || : &
# wait for the file $ARTIFACT_DIR/logging-test-result to exist - the contents
# will be PASS or FAIL
timeout=240
# 240 * 30 seconds = 7200 seconds = 2 hours
wait_func() {
    result=$( oc exec logging-ci-test-runner -- cat $ARTIFACT_DIR/logging-test-result 2> /dev/null ) && [ -n "$result" ]
}
if ! wait_for_condition wait_func $timeout 30 > ${ARTIFACT_DIR}/test_output 2>&1 ; then
    echo ERROR: logging tests did not complete after $(( timeout * 30 )) seconds
    logging_err_exit
fi
result=$( oc exec logging-ci-test-runner -- cat $ARTIFACT_DIR/logging-test-result 2> /dev/null )

# copy the artifacts out of the test runner pod
oc rsync --strategy=tar logging-ci-test-runner:$ARTIFACT_DIR/ $ARTIFACT_DIR > ${ARTIFACT_DIR}/syncout 2>&1

# tell the logging test pod we are done copying artifacts
if oc exec logging-ci-test-runner -- "touch $ARTIFACT_DIR/artifacts-done 2> /dev/null" ; then
    echo notified logging-ci-test-runner - done with artifacts
else
    echo error notifying logging-ci-test-runner - $? - ignoring
fi

if [ "$result" = PASS ] ; then
    exit 0
else
    exit 1
fi
