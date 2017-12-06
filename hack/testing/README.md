# About hack/testing

# test-* scripts
These tests are wrapper scripts to those found in `$HOME/test` and perform test specific setup and cleanup operations for the test

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
