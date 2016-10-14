# Modifications to Fluentd Metadata Retrieval Proposal

##Motivation
In the current design (v3.4) of the EFK stack, there is a Fluentd pod deployed to each Openshift node. Fluentd is responsible for reading container logs, adding pod metadata (e.g. labels, namespace) to individual log entries, and sending the logs to the Elasticsearch cluster. The pod metadata is sourced by watching the Openshift API server for Pod information via the [Kubernetes Metadata Filter](https://github.com/fabric8io/fluent-plugin-kubernetes_metadata_filter)[2]. Testing at larger scales of Openshift clusters has shown issues where Fluentd is unable to connect to the API server because it is limited by the **maxRequestsInFlight** configuration setting [1].  This results in logs not being shipped to the aggregator and thus being unavailable.

##Proposal - Short Term (3.4)
1. Leave the value as-is and note that it must be adjusted to account for # of nodes plus some headroom (swag @ 10%?).
1. Increase the default to our current maximum supported node count, plus some headroom.
1. Increasing maxRequestsInflight upstream

##Proposal - Long Term
###Option 1 - Admission Controller
1. Create a simple admission controller which simply embeds the necessary meta-data as env-variables into the pods on submission.  In this way every pod that is run on the system will have its data locally.
1. Mount the docker socket into the Fluentd pod such that it can query containers env-variables.
1. Remove any watches from the Fluentd pods, thereby eliminating excessive traffic from the node.

This will require:
* Admission controller introduced to [Openshift Origin](https://github.com/openshift/origin)
* Deployment changes (e.g. deployer or ansible)
* A new Fluentd plugin
* Support setup (e.g. ci, packaging, github/enterprise repo)

Questions:
1. How long is metadata available?  It is limited by Pod GC?
1. Can we completely eliminate a filter[1] to provide metadata? Consider keeping some implementation that contacts API server as a fallback mechanism

###Option 2 - Rsyslog collector to Fluentd (Augmentor)
Utilize rsyslog to collect logs and forward them to Fluentd.  There is initial work to support this and would allow a 'vanilla' rsyslog implementation to work in conjunction with some smaller number of Fluentd pods to add metadata.

This will require:
* Deployment changes (e.g. deployer or ansible)
* Packing and containerization of rsyslog?

Questions:
1. Does this require any Fluentd plugin changes?
1. Does this require modifications to Fluentd? (e.g. how it receives logs, ships logs)
1. How many Fluentd instance are needed?
1. Where do Fluentd instance get deployed? Infra nodes only?

###Option 3 - Fluentd (Collector) to Fluentd (Augmentor)
This is similiar to **Option 2** but it utilizes Fluentd as the collector instead of rsyslog.

This will require:
* Deployment Changes (e.g. deployer or ansible)

Questions:
See questions from **Option 2**

###Option 4 - Metadata service
Introduce a service to the deployment of EFK that is solely responsible for watching Pods and gathering metadata that is provided by the Kubernetes Metadata filter.  The service is queried by Fluentd to retrieve the required information.  The expectation is instead of having N Fluentd images contacting the API server that there are some significantly less number of 'Metadata services' that provide the same information with reduced request.

This will require:
* New Fluend plugin to interact with the new service
* Creation and maintenance of the service code
  * e.g. technology choice, github repo, deployment changes (ansible), enterprise repo, ci, packaging

Questions:
1. What scale is required? X instances per N cluster nodes
1. Impact on cluster infrastructure
1. Do instances need to be constrained to infra nodes?
## References
[1] https://bugzilla.redhat.com/show_bug.cgi?id=1384626
[2] https://github.com/fabric8io/fluent-plugin-kubernetes_metadata_filter
