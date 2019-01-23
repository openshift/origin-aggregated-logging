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
pushd $gopath/src/github.com/openshift/cluster-logging-operator > /dev/null
# edit the deployments - for the logging images, use pipeline
# for example, change this:
# docker.io/openshift/origin-logging-elasticsearch5:latest
# to this:
# pipeline:logging-elasticsearch5
sed -i -e '/docker.io\/openshift\/origin-logging-/ {s,:latest,,; s,docker.io/openshift/origin-,registry.svc.ci.openshift.org/'${OPENSHIFT_BUILD_NAMESPACE}'/pipeline:,}' manifests/05-deployment.yaml
make undeploy || :
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
done
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
    exit 1
fi

# create secret for test and add $KUBECONFIG contents
oc create secret generic logging-ci-test-kubeconfig \
    --from-file=admin.kubeconfig.orig=$KUBECONFIG
# we're using the same image as what we are currently running in, just launching
# it in a pod in the remote cluster - so the pwd is the test root is the same
# there and here
if [ -n "${ARTIFACT_DIR:-}" ] ; then
    artifact_dir_arg="-p ARTIFACT_DIR=$ARTIFACT_DIR"
fi
oc process -p TEST_ROOT=$( pwd ) \
    -p TEST_NAMESPACE_NAME=$( oc project -q ) \
    -p TEST_IMAGE=registry.svc.ci.openshift.org/${OPENSHIFT_BUILD_NAMESPACE}/pipeline:src \
    ${artifact_dir_arg:-} \
    -f hack/testing/templates/logging-ci-test-runner-template.yaml | oc create -f -
timeout=600
for ii in $( seq 1 $timeout ) ; do
    if oc logs logging-ci-test-runner > /dev/null 2>&1 ; then
        break
    fi
    sleep 1
done
if [ $ii = $timeout ] ; then
    echo ERROR: failed to start logging-ci-test-runner
    oc describe pod logging-ci-test-runner || :
    oc get events || :
    exit 1
fi
oc logs -f logging-ci-test-runner 2>&1 | tee $ARTIFACT_DIR/logging-test-output &
# wait for the file $ARTIFACT_DIR/logging-test-result to exist - the contents
# will be PASS or FAIL
timeout=240
# 240 * 30 seconds = 7200 seconds = 2 hours
for ii in $( seq 1 $timeout ) ; do
    if result=$( oc exec logging-ci-test-runner -- cat $ARTIFACT_DIR/logging-test-result 2> /dev/null ) && [ -n "$result" ] ; then
        break
    fi
    sleep 30
done
if [ $ii = $timeout ] ; then
    echo ERROR: logging tests did not complete after $(( timeout * 30 )) seconds
    oc describe pod logging-ci-test-runner || :
    oc get events || :
    exit 1
fi

# copy the artifacts out of the test runner pod
oc rsync --strategy=tar --progress=true logging-ci-test-runner:$ARTIFACT_DIR/ $ARTIFACT_DIR

# tell the logging test pod we are done copying artifacts
oc exec logging-ci-test-runner -- "touch $ARTIFACT_DIR/artifacts-done"

if [ "$result" = PASS ] ; then
    exit 0
else
    exit 1
fi
