#!/bin/bash
set -euxo pipefail

pkgs=""
if ! type -p oc > /dev/null 2>&1 ; then
    yum -y install centos-release-openshift-origin311
    pkgs="$pkgs origin-clients"
fi
if ! type -p jq > /dev/null 2>&1 ; then
    yum -y install epel-release
    pkgs="$pkgs jq"
fi
if ! type -p bc > /dev/null 2>&1 ; then
    pkgs="$pkgs bc"
fi
if ! type -p sudo > /dev/null 2>&1 ; then
    pkgs="$pkgs sudo"
fi
if ! type -p htpasswd > /dev/null 2>&1 ; then
    pkgs="$pkgs httpd-tools"
fi
if ! type -p watch > /dev/null 2>&1 ; then
    pkgs="$pkgs procps-ng"
fi
if ! type -p base64 > /dev/null 2>&1 ; then
    pkgs="$pkgs coreutils"
fi
if [ -n "$pkgs" ] ; then
    yum -y install $pkgs
fi
oc login -u system:admin

if [ -n "${ARTIFACT_DIR:-}" ] ; then
    # ARTIFACT_DIR is set by ci - it has a different meaning
    # in that context - here we use it for the OS_OUTPUT_SCRIPTPATH
    if [ ! -d $ARTIFACT_DIR ] ; then
        mkdir -p $ARTIFACT_DIR
    fi
    SAVE_ARTIFACT_DIR=$ARTIFACT_DIR
    export OS_OUTPUT_SCRIPTPATH=$ARTIFACT_DIR/scripts
    unset ARTIFACT_DIR
fi

if TEST_ONLY=${TEST_ONLY:-true} SKIP_TEARDOWN=true JUNIT_REPORT=true make test ; then
  rc=0
  echo PASS > ${SAVE_ARTIFACT_DIR:-/tmp}/logging-test-result
else
  rc=1
  echo FAIL > ${SAVE_ARTIFACT_DIR:-/tmp}/logging-test-result
fi
echo logging tests finished at $( date --rfc-3339=sec )

# caller will now get artifacts - wait until that is complete
exithandler() {
    local resultcode=$?
    set +eu
    echo in exithandler rc = $rc ii = $ii ts = $( date --rfc-3339=sec )
    exit $resultcode
}
trap "exithandler" EXIT

if [ -n "${SAVE_ARTIFACT_DIR:-}" ] ; then
    timeout=600
    set +x
    for ii in $( seq 1 $timeout ) ; do
        if [ -f $SAVE_ARTIFACT_DIR/artifacts-done ] ; then
            break
        fi
        sleep 1
    done
    set -x
    if [ $ii = $timeout ] ; then
        echo ERROR: caller did not write $SAVE_ARTIFACT_DIR/artifacts-done and collect artifacts after $timeout seconds
        ls -alrtF $SAVE_ARTIFACT_DIR
    else
        echo INFO: artifact collection is done $SAVE_ARTIFACT_DIR/artifacts-done
    fi
fi
exit $rc
