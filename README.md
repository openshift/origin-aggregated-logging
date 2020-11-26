# OpenShift Logging

## Developer documentation

Documentation that applies to the entire logging stack, all operators and their operands.

* [Architecture overview and status](./docs/architecture/index.html)
* [Data Model](./docs/com.redhat.viaq-openshift-project.asciidoc)

## Image definitions

This repo contains image definitions for the components of the OpenShift Logging stack for releases 4.x and later.
These [components images](#components), abbreviated as the "EFK" stack, include: Elasticsearch, Fluentd, Kibana.
Please refer to the [cluster-logging-operator](https://github.com/openshift/cluster-logging-operator) and [elasticsearch-operator](https://github.com/openshift/elasticsearch-operator) for information regarding the operators which deploy these images.

The primary features this integration provides:
* [Multitenant support](https://github.com/openshift/elasticsearch-operator/blob/master/docs/access-control.md) to isolate logs from various project namespaces
* OpenShift OAuth2 integration
* Log Forwarding
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
them with metadata, and forwarding them to the default logstore or other destinations defined by administrators.

### Kibana

Kibana presents a web UI for browsing and visualizing logs in Elasticsearch.


### Cluster Logging Operator

The [**cluster-logging-operator**](https://github.com/openshift/cluster-logging-operator) orchestrates the deployment
of the cluster logging stack including: resource definitions, key/cert generation, component
start and stop order.


## Issues

Any issues can be filed at [Red Hat Bugzilla](https://bugzilla.redhat.com).  Please
include as many [details](docs/issues.md) as possible in order to assist in issue resolution along with attaching a [must gather](https://github.com/openshift/cluster-logging-operator/tree/master/must-gather) output.


## Contributions

To contribute to the development of origin-aggregated-logging, see [REVIEW.md](./docs/REVIEW.md)
