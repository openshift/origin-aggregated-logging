#!/bin/bash
# this is meant to be sourced - called in the current context
# of the script as TEST_COMMAND - rather than called as a separate
# fork/exec script so that variables such as OPENSHIFT_BUILD_NAMESPACE and
# ARTIFACT_DIR will be available - see
# https://github.com/openshift/release/blob/master/ci-operator/templates/cluster-launch-installer-src.yaml
# where the script will sourced

set -eux

if [ ${LOGGING_DEPLOY_MODE:-} == "upgrade" ] ; then
	echo ">>>>>>> Skipping upgrade test for now <<<<<<"
	exit 0
fi
. hack/test-e2e.sh