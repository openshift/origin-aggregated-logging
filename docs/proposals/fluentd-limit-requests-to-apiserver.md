# Modifications to Fluentd Metadata Retrieval Proposal

##Motivation
In the current design (v3.4) of the EFK stack, there is a Fluentd pod deployed to each Openshift node. Fluentd is responsible for reading container logs, adding pod metadata (e.g. labels, annotations) to individual log entries, and sending the logs to the Elasticsearch cluster. The additional metadata, such as labels, augment log entries to allow users to intelligently query their deployed services.  The metadata acts to enrich the logs so users may logically group their services as a single, coherent application.

The pod metadata is currently sourced by watching the Openshift API server for Pod information via the [Kubernetes Metadata Filter](https://github.com/fabric8io/fluent-plugin-kubernetes_metadata_filter)[2]; Each watch maintains an open connection to the API server. Testing at larger scales of Openshift clusters has shown issues where Fluentd is unable to connect to the API server because it is limited by the **maxRequestsInFlight** configuration setting [1].  The current deployment topology at scale:

* Results in logs not being shipped to the aggregator and thus being unavailable
* Limits the number of cluster nodes because of the cap on the number of open connections

This proposal addresses both the short and long term solutions to resolve the connection issues being experienced using the v3.4 EFK stack.
### Considerations
1. OpenShift Logging is not the only consumer of OpenShift log messages.  There are a significant number of OpenShift consumers who desire to use their existing logging infrastructure: Splunk, Elasticsearc.  We need to normalize log entries with metadata irrespective of the final destination.  This may dictate the deployment topology of a long term solution

##Proposal - Short Term (3.4)
1. Leave the value as-is and note that it must be adjusted to account for # of nodes plus some headroom (swag @ 10%?).
1. Increase the default to our current maximum supported node count, plus some headroom.
1. Increasing maxRequestsInflight upstream
1. **COMPLETE** ~~Modify Fluentd Metadata plugin to cache by namespace and pod name only~~[2][4]

##Proposal - Long Term
###Option 1 - Admission Controller
1. Create an admission controller which embeds the necessary metadata as envirnment variables into the pods on submission.  In this way every pod that is run on the system will have its data locally.
1. Mount the docker socket into the Fluentd pod such that it can query container's environment variables.
1. Remove any watches from the Fluentd pods to eliminating excessive traffic from the node.

This option implies log messages will never be updated when labels and annotations change since docker containers are immutable once they start.  It additionally binds the log normalization to the container runtime.

This will require:
* Admission controller introduced to [Openshift Origin](https://github.com/openshift/origin)
* Deployment changes (e.g. deployer or ansible)
* A new Fluentd plugin
* Support setup (e.g. ci, packaging, github/enterprise repo)

Questions:
1. How long is metadata available?  It is limited by Pod GC?
1. Can we completely eliminate a filter[1] to provide metadata? Consider keeping some implementation that contacts API server as a fallback mechanism
1. What is the acceptable 'staleness' of labels and annotations associated with logs?  Is it acceptible for logs to not receive label and annotation updates when a pod definition is updated?

###Option 2 - Rsyslog collector to Fluentd (Normalizer)
Utilize rsyslog to collect logs and forward them to Fluentd.  There is initial work to support this and would allow a 'vanilla' rsyslog implementation to work in conjunction with some smaller number of Fluentd pods to add metadata.  This would reduce the affects of scaling by:

1. Moving the normalization off the compute nodes
2. Reducing the number of open connections by utilizing a smaller number of normalizers to enrich all the logs in lieu of each Fluentd instance enriching its own logs.

This will require:
* Deployment changes (e.g. deployer or ansible)
* ~~Packing and containerization of rsyslog~~
  * Packaging and containerization tasks completed by CDA team

Questions:
1. Does this require any Fluentd plugin changes?
  * A: syslog input filter exists but is not encrypted[3]
2. Does this require modifications to Fluentd? (e.g. how it receives logs, ships logs)
  * A: Only the input to Fluentd changes.  Everything downstream remains the same
3. How many Fluentd instance are needed?
  * A: TBD
1. Where do Fluentd instance get deployed? Infra nodes only?

###Option 3 - Fluentd (Collector) to Fluentd (Normalizer)
This is similiar to **Option 2** but it utilizes Fluentd as the collector instead of rsyslog.  This scenerio becomes more complicated to scale and deploy because:
* Multiple configmaps to maintain (e.g. gather fluentd, enrichment fluentd)
* Potentially two daemonsets
* Certain nodes potentially more resource intensive (e.g. cpu, network, memory)

This will require:
* Deployment Changes (e.g. deployer or ansible)

Questions:
See questions from **Option 2**

###Option 4 - Metadata service
Introduce a service to the deployment of EFK that is solely responsible for watching Pods and gathering metadata that is provided by the Kubernetes Metadata filter.  The service is queried by Fluentd to retrieve the required information.  The expectation is instead of having N Fluentd pods contacting the API server that there are some significantly less number of 'Metadata services' that provide the same information with reduced request.

This will require:
* New Fluend plugin to interact with the new service
* Creation and maintenance of the service code
  * e.g. technology choice, github repo, deployment changes (ansible), enterprise repo, ci, packaging

Questions:
1. What scale is required? X instances per N cluster nodes
1. Impact on cluster infrastructure
1. Do instances need to be constrained to infra nodes?

###Option 5 - Kubelet Handler for Pod metadata
Add a handler to the Kubelet to allow pod information to be queried by name or to instigate a watch.  Ideally, the endpoint would feature the same characteristics of the API master pod endpoint to allow reuse of the existing metadata filter [2].  This would completely eliminate connections to the master.

This will require:
* Changes in Openshift origin
* Deployment changes

Questions:
1. Changes to security policy to allow specific roles to access endpoint?

## References
[1] https://bugzilla.redhat.com/show_bug.cgi?id=1384626
[2] https://github.com/fabric8io/fluent-plugin-kubernetes_metadata_filter
[3] http://docs.fluentd.org/articles/in_syslog
[4] https://github.com/fabric8io/fluent-plugin-kubernetes_metadata_filter/pull/44
