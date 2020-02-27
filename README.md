# Origin-Aggregated-Logging - DONT MERGE ME
* Build and Push - master - [![Build and Push - master](https://ci.openshift.redhat.com/jenkins/buildStatus/icon?job=build-and-release-latest-origin-aggregated-logging)](https://ci.openshift.redhat.com/jenkins/view/All/job/build-and-release-latest-origin-aggregated-logging/)
* Build and Push - branch release - [![Build and Push - branch release](https://ci.openshift.redhat.com/jenkins/buildStatus/icon?job=push_origin_aggregated_logging_release)](https://ci.openshift.redhat.com/jenkins/view/All/job/push_origin_aggregated_logging_release/)
* Test Pull Request - master/journald - [![Test Pull Request - master/journald](https://ci.openshift.redhat.com/jenkins/buildStatus/icon?job=test_pull_request_openshift_ansible_logging)](https://ci.openshift.redhat.com/jenkins/view/All/job/test_pull_request_openshift_ansible_logging/)
* Test Pull Request - master/json-file - [![Test Pull Request - master/json-file](https://ci.openshift.redhat.com/jenkins/buildStatus/icon?job=test_pull_request_origin_aggregated_logging_json_file)](https://ci.openshift.redhat.com/jenkins/view/All/job/test_pull_request_origin_aggregated_logging_json_file/)

This repo contains the image definitions for the components of the cluster logging
stack as well as tools for building and deploying them.  The cluster logging subsystem
consists of multiple [components](#components) abbreviated as the "EFK"
stack: Elasticsearch, Fluentd, Kibana.

The primary features this integration provides:
* [Multitenant support](docs/access-control.md) to isolate logs from various project namespaces
* Openshift OAuth2 integration
* Historical log discovery and visualization
* Log aggregation of pod and node logs

Information to build the images from github source using an OKD
deployment is found [here](HACKING.md).  See the [quickstart](https://github.com/openshift/cluster-logging-operator#quick-start) guide to deploy cluster logging.

Please check the [release notes](docs/release_notes.md) for deprecated features or breaking changes .

## Components

The cluster logging subsystem consists of multiple components commonly abbreviated
as the "ELK" stack (though modified here to be the "EFK" stack).

### Elasticsearch

Elasticsearch is a Lucene-based indexing object store into which logs
are fed. Logs for node services and all containers in the cluster are
fed into one deployed cluster. The Elasticsearch cluster should be deployed
with redundancy and persistent storage for scale and high availability.

### Fluentd

Fluentd is responsible for gathering log entries from nodes, enriching
them with metadata, and feeding them into Elasticsearch.

### Kibana

Kibana presents a web UI for browsing and visualizing logs in Elasticsearch.

### Logging auth proxy

In order to authenticate the Kibana user against OpenShift's Oauth2, a
proxy is required that runs in front of Kibana.

### Curator

Curator allows the admin to remove old indices from Elasticsearch on a per-project
basis.

### Cluster Logging Operator

The [**cluster-logging-operator**](https://github.com/openshift/cluster-logging-operator) orchestrates the deployment
of the cluster logging stack including: resource definitions, key/cert generation, component
start and stop order.

## Cluster Logging Health

Determining the health of an EFK deployment and if it is running can be assessed
by running the `check-EFK-running.sh` and `check-logs.sh` [e2e tests](hack/testing/).
Additionally, see [Checking EFK Health](docs/checking-efk-health.md)

## Issues

Any issues against the origin stack can be filed at https://github.com/openshift/origin-aggregated-logging/issues.  Please
include as many [details](docs/issues.md) as possible in order to assist us in resolving the issue.

## Troubleshooting CI
[Troubleshooting CI](docs/troubleshooting-ci.md)

## Updating hack/vendor/olm-test-script
Use curl to grab the tarball from github:
```
curl -s -L https://api.github.com/repos/ORG-or-USERNAME/REPO/tarball/BRANCH | tar -C hack/vendor/olm-test-script --strip-components=1 -x -z -f -
```
for example:
```
curl -s -L https://api.github.com/repos/shawn-hurley/olm-test-script/tarball/master | tar -C hack/vendor/olm-test-script --strip-components=1 -x -z -f -
```
