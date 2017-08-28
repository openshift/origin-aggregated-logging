# Origin-Aggregated-Logging [![Build Status](https://ci.openshift.redhat.com/jenkins/buildStatus/icon?job=test-origin-aggregated-logging)](https://ci.openshift.redhat.com/jenkins/job/test-origin-aggregated-logging)

This repo contains the image definitions for the components of the logging
stack as well as tools for building and deploying them.  The logging subsystem
consists of multiple [components](#Components) abbreviated as the "EFK"
stack: Elasticsearch, Fluentd, Kibana.

The primary features this integration provides:
* [Multitenant support](docs/access-control.md) to isolate logs from various project namespaces
* Openshift OAuth2 integration
* Historical log discovery and visualization
* Log aggregation of pod and node logs

Information to build the images from github source using an OpenShift
Origin deployment is found [here](HACKING.md).  To deploy the components from built or supplied images, see the
[openshift_logging role](https://github.com/openshift/openshift-ansible/tree/master/roles/openshift_logging)
in the OpenShift Ansible project.  You will need to be familiar with [Ansible](https://github.com/ansible/ansible)
principles and create an inventory file to modify the [default variables](https://github.com/openshift/openshift-ansible/blob/master/roles/openshift_logging/defaults/main.yml)
for your OpenShift logging cluster.  For the impatient, see the [quickstart](docs/quickstart.md) guide.

**NOTE:** If you are running OpenShift Origin using the
[All-In-One docker container](https://docs.openshift.org/latest/getting_started/administrators.html#running-in-a-docker-container)
method, you MUST add `-v /var/log:/var/log` to the `docker` command line.
OpenShift must have access to the container logs in order for Fluentd to read
and process them.

## Components

The logging subsystem consists of multiple components commonly abbreviated
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

### OpenShift Ansible Logging Role (***openshift_logging***)

The [**openshift-ansible**](https://github.com/openshift/openshift-ansible) ```openshift_logging``` role orchestrates the deployment
of the logging stack including: resource definitions, key/cert generation, component
start and stop order.

## EFK Health

Determining the health of an EFK deployment and if it is running can be assessed
by running the `check-EFK-running.sh` and `check-logs.sh` [e2e tests](hack/testing/).
Additionally, see [Checking EFK Health](docs/checking-efk-health.md)

## Issues

Any issues against the origin stack can be filed at https://github.com/openshift/origin-aggregated-logging/issues.  Please
include as many [details](docs/issues.md) as possible in order to assist us in resolving the issue.
