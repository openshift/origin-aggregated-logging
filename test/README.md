# Guidelines for Writing Tests

## Assumptions & Requirements

1. Directory paths should be well formed such that they can be run from any directory.
1. Test scripts in the `origin-aggregated-logging/test` directory assume they are run against a functional Openshift cluster that was setup prior to the execution of the test script.
1. Each script in `origin-aggregated-logging/test` should has a companion script in `origin-aggregated-logging/hack/testing` which can be used to launch the test and do requisite setup steps.
1. Each script in `origin-aggregated-logging/test` performs cleanup logic to reset the state of the cluster and logging stack

```sh
#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"


os::test::junit::declare_suite_start "test/<TESTNAME>"

<TEST LOGIC>

```

## Role of Companion scripts in hack/testing

The wrapper or companion script for each test is responsible for

* Setup logic that is specific to the test
* Cleanup logic that is specific to the test

```sh
#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}" )/../lib/init.sh"

exec ${OS_O_A_L_DIR}/test/<testname>

```

## Individual Test Cleanup

```sh
cleanup(){
    local return_code="$?"

	<DO TEST CLEAN UP CODE>

    # this will call declare_test_end, suite_end, etc.
    os::test::junit::reconcile_output

    exit $return_code
}
trap "cleanup" EXIT

```
# Enabling Debug output
Enabling debug output from `os::log::debug` is done by setting the `$OS_DEBUG` environment variable
