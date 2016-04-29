# About the E2E testing script

The aggregated logging subsystem consists of multiple components commonly
abbreviated as the "ELK" stack (though modified here to be the "EFK"
stack).

## e2e-test.sh

This script runs the two underlying scripts - `check-EFK-running.sh` and
`check-logs.sh`.  If the first script does not complete successfully, then
`check-logs.sh` will not be run.

## check-EFK-running.sh

The purpose of this script is to check and verify that the necessary components
are available and, if need be, running.  Providing an argument of `true` to
`e2e-test.sh` will then check based on having built the EFK with the
`ENABLE_OPS_CLUSTER=true` option.  Note: omitting the argument will default to
`false` meaning that an OPS cluster was not used.

Further environment variables can be provided as described here.

## check-logs.sh

The purpose of this script is to verify that logs for the local node that are
found within Elasticsearch are available within the correct local log files.

This means that if there is not at least one Elasticsearch pod running this
will not be able to succeed.

If logs have not yet been pushed to Elasticsearch this will not be able to
succeed either and an error message will be printed out stating that indices
were not found.  Otherwise it will query for messages within the indices found
to have been created (based on the logs of the Elasticsearch pods).

## check-logs.go

This Go script will query the appropriate ES pod (if an OPS cluster was used)
and check the local log files for the each result message.

## check-curator.sh

The purpose of this script is to verify the curator pod is working.  It will
add curator configs for the following projects and trimming parameters:

* project "project-dev" logs should be deleted if they are more than a day old
* project "project-qe" logs should be deleted if they are more than a week old
* project "project-prod" logs should be deleted if they are more than 4 weeks old
* project ".operations" logs should be deleted if they are more than 2 months
old

The script will create ES indices for these projects using the fluentd user
credentials (which is allowed to create ES indices and records).  One index per
project will be for "today", and one will be for outside of the time window for
the project as described above.

The script will redeploy the curator pod using the trimming parameters as
described above and wait for the new curator pod with the new config to be
running.

The script will then use the curator credentials to run curator to list the
indices afterwards, and verify that the indices created for "today" are still
present, and the indices created outside of the time window for each project
have been removed.

## Environment values for testing

In addition to providing the argument `true` to `e2e-test.sh` to indicate that
an OPS cluster is used, the following environment values can be used to
change behavior of the scripts.

The format for the following would be
`ENV_VAR1=value [ENV_VAR2=value2] ./e2e-test.sh`

```
VERBOSE                 | If "true", the scripts will print out each command as executed | default: "false"
KIBANA_CLUSTER_SIZE     | The num of Kibana pod replicas | default: 1
KIBANA_OPS_CLUSTER_SIZE | The num of Kibana Ops pod replicas if OPS cluster is used | default: 1
ES_CLUSTER_SIZE         | The num of Elasticsearch pod replicas | default: 1
ES_OPS_CLUSTER_SIZE     | The num of Elasticsearch Ops pod replicas if OPS cluster is used | default: 1
TIMES                   | The maximum number of attempts to try for checking if ES is ready for queries | default: 10
QUERY_SIZE              | The maximum number of query results returned for an index | default: 500
```

# About the performance testing

All scripts starting with `perf-` prefix are considered performance tests.
Performance tests are different from other (non-performance) tests in that
they may run for a long time and they output performance metrics in the end
that are gathered and stored into benchmark repository.

Note: performance test results gathering to central repository is WIP.
The results stay on the Jenkins server for now. For status on central
 benchmark repository implementation please check
 [relevant trello card](https://trello.com/c/Xi1uCZiA/255-performance-test-results-ui-visualization-logging). 

Performance tests are run via two means:

- by adding comment containing "`[testperf]`" string to individual pull request
- on a regular basis performance tests are run by Jenkins

## perf-test-operations.sh

This is initial example of performance test.
