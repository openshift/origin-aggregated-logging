#!/bin/bash
# this is meant to be sourced - called in the current context
# of the script as TEST_COMMAND - rather than called as a separate
# fork/exec script so that variables such as OPENSHIFT_BUILD_NAMESPACE and
# ARTIFACT_DIR will be available - see
# https://github.com/openshift/release/blob/master/ci-operator/templates/cluster-launch-installer-src.yaml
# where the script will sourced

# it is expected the image was built with golang
# but all of this operator stuff could go away if the ci test is changed to
# deploy logging using OLM and a subscription
gopath=$( go env GOPATH | cut -f1 -d: )
if [ ! -d $gopath/src/github.com/openshift/elasticsearch-operator ] ; then
    git clone https://github.com/${ESO_OPERATOR_REPO:-openshift}/elasticsearch-operator \
    --branch ${ESO_OPERATOR_BRANCH:-master} \
    $gopath/src/github.com/openshift/elasticsearch-operator
fi
if [ ! -d $gopath/src/github.com/openshift/cluster-logging-operator ] ; then
    git clone https://github.com/${CLO_OPERATOR_REPO:-openshift}/cluster-logging-operator \
    --branch ${CLO_OPERATOR_BRANCH:-master} \
    $gopath/src/github.com/openshift/cluster-logging-operator
fi
testroot=$( pwd )
pushd $gopath/src/github.com/openshift/cluster-logging-operator > /dev/null
if [ -z "${ARTIFACT_DIR:-}" ] ; then
    ARTIFACT_DIR=/tmp/artifacts
    if [ ! -d $ARTIFACT_DIR ] ; then
        mkdir -p $ARTIFACT_DIR
    fi
fi
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
    sed -e 's,docker.io/openshift/origin-logging-\(..*\):latest,'"$imageprefix"'pipeline:logging-\1,' \
        -e 's,quay.io/openshift/origin-logging-\(..*\):latest,'"$imageprefix"'pipeline:logging-\1,' \
        -i manifests/05-deployment.yaml
    testimage=${imageprefix}pipeline:src
else
    # running in a dev env
    OPENSHIFT_BUILD_NAMESPACE=openshift
    registry=$( oc -n $OPENSHIFT_BUILD_NAMESPACE get is -l logging-infra=development -o jsonpath='{.items[0].status.dockerImageRepository}' | \
        sed 's,/[^/]*$,/,' )
    sed -e '/docker.io\/openshift\/origin-logging-/ {s,docker.io/openshift/origin-,'"$registry"',}' \
        -e '/quay.io\/openshift\/origin-logging-/ {s,quay.io/openshift/origin-,'"$registry"',}' \
        -i manifests/05-deployment.yaml
    testimage=${registry}logging-ci-test-runner:latest
    testroot=/go/src/github.com/openshift/origin-aggregated-logging
fi
make undeploy > /dev/null 2>&1 || :
REMOTE_CLUSTER=true make deploy-example-no-build
popd > /dev/null
oc project openshift-logging
timeout=300
for ii in $( seq 1 $timeout ) ; do
    if oc get pods 2> /dev/null | grep -q 'kibana.*Running' && \
        oc get pods 2> /dev/null | grep -v 'elasticsearch-operator' | grep -q 'elasticsearch.*Running' && \
        oc get pods 2> /dev/null | grep -q 'fluentd.*Running' ; then
        break
    fi
    sleep 1
done > ${ARTIFACT_DIR}/test_output 2>&1
if [ $ii = $timeout ] ; then
    echo ERROR: operator did not start pods after $timeout seconds
    oc get deploy || :
    oc get pods || :
    oc get elasticsearch || :
    oc get clusterlogging || :
    oc describe pods
    for p in $( oc get pods -o jsonpath='{.items[*].metadata.name}' ) ; do
        for container in $( oc get po $p -o jsonpath='{.spec.containers[*].name}' ) ; do
            echo pod $p container $container
            oc logs -c $container $p
        done
    done
    oc get events || :
    cat ${ARTIFACT_DIR}/test_output
    exit 1
fi

# the ci test pod, kibana pod, and fluentd pod, all have to run on the same node
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
timeout=600
for ii in $( seq 1 $timeout ) ; do
    if oc logs logging-ci-test-runner > /dev/null 2>&1 ; then
        break
    fi
    sleep 1
done > ${ARTIFACT_DIR}/test_output 2>&1
if [ $ii = $timeout ] ; then
    echo ERROR: failed to start logging-ci-test-runner
    oc describe pod logging-ci-test-runner || :
    oc get events || :
    cat ${ARTIFACT_DIR}/test_output
    exit 1
fi
# this will exit with error when the pod exits - ignore that error
oc logs -f logging-ci-test-runner 2>&1 | tee $ARTIFACT_DIR/logging-test-output || : &
# wait for the file $ARTIFACT_DIR/logging-test-result to exist - the contents
# will be PASS or FAIL
timeout=240
# 240 * 30 seconds = 7200 seconds = 2 hours
for ii in $( seq 1 $timeout ) ; do
    if result=$( oc exec logging-ci-test-runner -- cat $ARTIFACT_DIR/logging-test-result 2> /dev/null ) && [ -n "$result" ] ; then
        break
    fi
    sleep 30
done > ${ARTIFACT_DIR}/test_output 2>&1
if [ $ii = $timeout ] ; then
    echo ERROR: logging tests did not complete after $(( timeout * 30 )) seconds
    oc describe pod logging-ci-test-runner || :
    oc get events || :
    cat ${ARTIFACT_DIR}/test_output
    exit 1
fi

# copy the artifacts out of the test runner pod
oc rsync --strategy=tar logging-ci-test-runner:$ARTIFACT_DIR/ $ARTIFACT_DIR > ${ARTIFACT_DIR}/syncout 2>&1

# tell the logging test pod we are done copying artifacts
if oc exec logging-ci-test-runner -- "touch $ARTIFACT_DIR/artifacts-done" ; then
    echo notified logging-ci-test-runner - done with artifacts
else
    echo error notifying logging-ci-test-runner - $? - ignoring
fi

if [ "$result" = PASS ] ; then
    exit 0
else
    exit 1
fi
