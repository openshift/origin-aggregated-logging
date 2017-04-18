# Origin-Aggregated-Logging [![Build Status](https://ci.openshift.redhat.com/jenkins/buildStatus/icon?job=test-origin-aggregated-logging)](https://ci.openshift.redhat.com/jenkins/job/test-origin-aggregated-logging)

This repo contains the image definitions for the components of the logging
stack as well as tools for building and deploying them.  The logging subsystem
consists of multiple [components](#Components) abbreviated as the "EFK" 
stack: Elasticsearch, Fluentd, Kibana.

The primary features this integration provides:

* Multitenant support to isolate logs from various project namespaces
* Openshift OAuth2 integration
* Historical log discovery and visualization
* Log aggregation of pod and node logs

Information to build the images from github source using an OpenShift
Origin deployment is found [here](HACKING.md).  To deploy the components from built or supplied images, see the [deployer](./deployer).

NOTE: If you are running OpenShift Origin using the
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

### Deployer

The deployer enables the user to generate all of the necessary
key/certs/secrets and deploy all of the components in concert.

### Curator

Curator allows the admin to remove old indices from Elasticsearch on a per-project
basis.

## Adding Elasticsearch replicas

If you need to scale up the number of Elasticsearch instances your cluster uses
it is not as simple as changing the number of replicas. This is due to the nature
of Persistent volumes and how Elasticsearch is configured to store its data.

Instead, you will need to create a Deployment Configuration for each replica.

The Deployer created templates during installation with the Elasticsearch
configurations provided to it: `logging-es-template` and `logging-es-ops-template`
if the Deployer was run with `ENABLE_OPS_CLUSTER=true`.

To create an additional Deployment Configuration, run the `oc new-app` command
against the cluster you'd like to scale up for (`logging-es-template` or
`logging-es-ops-template`).

#### Note
  With the above command, your Deployment Configuration will be created without
  a Persistent Volume. If you would like to create a replica with a Persistent
  Volume attached to it upon creation you can instead run the following command
  to create your DC with a PVC attached.

    $ oc process {your_es_cluster_template} | oc volume -f - \
       --add --overwrite --name=elasticsearch-storage \
       --type=persistentVolumeClaim --claim-name={your_pvc}`

## EFK Health

Determining the health of an EFK deployment and if it is running can be assessed
by running the `check-EFK-running.sh` and `check-logs.sh` [e2e tests](hack/testing/).
Additionally, see [Checking EFK Health](deployer/README.md#checking-efk-health).
