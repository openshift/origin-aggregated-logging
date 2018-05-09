# Logging Roadmap

This document is intended to provides a high level overview of the direction
of the Openshift Aggregated Logging infrastructure.

## Primary Use Cases
* As an application owner, I want to view the logs for my pods even when the pods have been deleted
* As a cluster operator, I want infrastructure logs forwarded to an existing log aggregation solution
* As a cluster operator, I want application logs forwarded to an existing log aggregation solution

## Release 3.10 Changes

### Documentation Changes:
* Relax any verbiage that suggests records are uniquely associated to their source
* State all log collection and normalization is **'best effort'** (e.g. add labels)
* Deprecation of `_ops_` inventory variables
* Potential changes to index format (e.g. **project.proj_name.uuid.date** to **project.proj_name.date**)

## Release 3.11 (or later) Changes
* Modify collector to simplify metadata normalization
* Modify collector to simplify index format
* Modify Elasticsearch plugin to seed index-patterns based on index format

## Release 3.12
* Replace fluentd as a log collector

## Deprecations Notes
### Indexing Uniqueness Guarantee
The available container runtimes provide minimal information to identify the source
of log messages.  This information is: namespace, pod name, container id.  This
initial metadata is not sufficient to uniquely identify the source across time and
space.  The nature of log collection is such that the collection and normalization of logs may occur after a pod was deleted and there is no additional information
to be retrieved from the API server (e.g. labels, annotations).  

Consider the case of a pod that is generating logs and the namespace is deleted but
the log collector has yet to process its logs.  Assuming the collector has no additional
knowledge about the source, there is no way to distinguish the log messages from a
similarly named pod and namespace if the namespace or pod name are reused. This
potentially results in logs being indexed and annotated to an index that is not
owned by the user who deployed the pod.

In general, there is no other Openshift infrasture component the provides guarantees
of uniqueness in spirit of what the logging stack is attempting to achieve.  The logging
solution was never intended to offer this guarantee.  Modifications are intended
to relax this assumption and simplify the pipeline from source to aggregation.

### Operations Deployment of Logging Stack
There are few known (if any) deployments of an 'operations' logging stack as is
possible using the current deployment methodology.  Generally, the current model
is to set all `_ops_` inventory variables and enable `_ops_` deployment.  This
has complicated the deployment model and requires unnecessary maintenance.  The
proposal is to reuse roles where applicable and advise users to supply a separate
operations inventory.  This will better allow control of: deploying operation dedicated
logging clusters, configuring log collectors to send logs off-cluster.
