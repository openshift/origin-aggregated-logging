Collect and store kubernetes events
===
By kubernetes events we understand log messages internal to kubernetes, accessible through the kubernetes API `/api/v1/events?watch=true`, originally stored in etcd. The etcd storage has time and performance constraints, therefore, we would like to collect and store them permanently in EFK.

How are the logs collected
---
By default, fluentd is able to read any pod’s STDOUT and insert as an enriched log message to Elasticsearch. The eventrouter outputs the events as a JSON string, parseable by fluentd which sets the event related fields in the `_default_` namespace. The desired structure is achieved in PR to [ViaQ data model fluentd plugin](https://github.com/ViaQ/fluent-plugin-viaq_data_model/pull/9).

Selected implementation consists of:
- [eventrouter](https://github.com/openshift/openshift-ansible/pull/4973) - scraping the events from kubernetes API and printing as separate messages to STDOUT for further processing.
- [fluentd ViaQ data model plugin](https://github.com/ViaQ/fluent-plugin-viaq_data_model/pull/9) - transforming the log message to adhere to desired data model moving event related fields to nest under the `kubernetes` field.
    
![design_proposal_image](https://cdn.rawgit.com/wozniakjan/origin-aggregated-logging/37bb71012f7a0008b929bb88352f78ad023dbe15/docs/proposals/kube_event_collection.svg)

What do the event logs contain
---
The logs contain all of the standard fields and metadata as described in [ViaQ CDM](https://github.com/ViaQ/elasticsearch-templates/tree/master/namespaces). Additionally, there are following fields from the event nested under the `kubernetes` field for deduplication:
```
pipeline_metadata.collector.original_raw_message <- message
message                                          <- event.message
@timestamp                                       <- event.metadata.creationTimestamp
kubernetes.event                                 <- event
```

How are the logs stored
---
This proposal would push kubernetes events to the same Elasticsearch instance that is a part of the Openshift Aggregated Logging stack. There are no intentions in the initial release to provide alternatives. The events would flow via fluentd or mux, so that they can be properly formatted and routed e.g. if the customer wants to ship logs external to the cluster to splunk, that logic is currently handled in fluentd/mux.

The eventrouter is deployed by default to the `default` namespace, therefore, fluentd inserts all of its logs to the `.operations.*` index in Elasticsearch. This will use the curator configuration for the `.operations.*` indices, which by default are deleted if more than 31 days old.

Example of a log containing event:
```
{
  docker" : {
    "container_id" : "a29c7d9cb2af947609d406308f366c4f862675d5211e4172dbfa3249ec4dfd66"
  },
  "kubernetes" : {
    "container_name" : "kube-eventrouter",
    "namespace_name" : "default",
    "pod_name" : "logging-eventrouter-1-jlwnd",
    "pod_id" : "29a7e785-8f1f-11e7-948b-5254002f560c",
    "labels" : {
      "component" : "eventrouter",
      "deployment" : "logging-eventrouter-1",
      "deploymentconfig" : "logging-eventrouter",
      "logging-infra" : "eventrouter",
      "provider" : "openshift"
    },
    "host" : "fed2",
    "master_url" : "https://kubernetes.default.svc.cluster.local",
    "namespace_id" : "46f37f2e-3fa8-11e7-a651-5254002f560c",
    "event" : {
      "metadata" : {
        "name" : "logging-kibana.14e042131d1e19e3",
        "namespace" : "logging",
        "selfLink" : "/api/v1/namespaces/logging/events/logging-kibana.14e042131d1e19e3",
        "uid" : "113cb573-8f1f-11e7-948b-5254002f560c",
        "resourceVersion" : "194435",
      },
      "involvedObject" : {
        "kind" : "DeploymentConfig",
        "namespace" : "logging",
        "name" : "logging-kibana",
        "uid" : "113820c8-8f1f-11e7-948b-5254002f560c",
        "apiVersion" : "v1",
        "resourceVersion" : "194433"
      },
      "reason" : "DeploymentCreated",
      "source" : {
        "component" : "deploymentconfig-controller"
      },
      "firstTimestamp" : "2017-09-01T14:08:45Z",
      "lastTimestamp" : "2017-09-01T14:08:45Z",
      "count" : 1,
      "type" : "Normal",
      "verb" : "ADDED"
    }
  },
  "hostname" : "fed2",
  "message" : "Readiness probe failed: Get https://10.128.1.84:5000/healthz: http2: no cached connection was available",
  "pipeline_metadata" : {
    "collector" : {
      "ipaddr4" : "10.128.1.156",
      "ipaddr6" : "fe80::2024:92ff:fe9f:b693",
      "inputname" : "fluent-plugin-in_tail",
      "name" : "fluentd openshift",
      "received_at" : "2017-09-01T14:09:30.920071487Z",
      "version" : "0.12.37 1.6.0",
      "original_raw_message" : "{\"verb\":\"ADDED\",\"event\":{\"metadata\":{\"name\":\"docker-registry-1-p08jj.14dffd4b9a4130eb\",\"namespace\":\"default\",\"selfLink\":\"/api/v1/namespaces/default/events/docker-registry-1-p08jj.14dffd4b9a4130eb\",\"uid\":\"897e67b4-8f16-11e7-948b-5254002f560c\",\"resourceVersion\":\"193589\",\"creationTimestamp\":\"2017-09-01T13:07:41Z\"},\"involvedObject\":{\"kind\":\"Pod\",\"namespace\":\"default\",\"name\":\"docker-registry-1-p08jj\",\"uid\":\"137a74fd-3fa9-11e7-a651-5254002f560c\",\"apiVersion\":\"v1\",\"resourceVersion\":\"174440\",\"fieldPath\":\"spec.containers{registry}\"},\"reason\":\"Unhealthy\",\"message\":\"Readiness probe failed: Get https://10.128.1.84:5000/healthz: http2: no cached connection was available\",\"source\":{\"component\":\"kubelet\",\"host\":\"fed2\"},\"firstTimestamp\":\"2017-08-31T17:08:21Z\",\"lastTimestamp\":\"2017-09-01T13:16:51Z\",\"count\":6,\"type\":\"Warning\"}}\n"
    }
  },
  "level" : "info",
  "@timestamp" : "2017-09-01T14:08:45Z"
}
```

Deployment
---
There will be a new role in openshift-ansible - [openshift_logging_eventrouter](https://github.com/openshift/openshift-ansible/pull/4973). The project where it deploys eventrouter is configurable, by default it is the default project.

All configurable options:
- `openshift_logging_install_eventrouter`: Eventrouter is not installed by default. If eventrouter is deployed as part of logging playbook, both `openshift_logging_install_eventrouter` and `openshift_logging_install_logging` must be set to True, for uninstallation, both must be set to False. If eventrouter is deployed without logging playbook on its own, only `openshift_logging_install_eventrouter` must be set appropriatelly.
- `openshift_logging_eventrouter_sink`: Select a sink for eventrouter, supported 'stdout' and 'glog'. Defaults to 'stdout'.
- `openshift_logging_eventrouter_nodeselector`: A map of labels (e.g. {"node":"infra","region":"west"} to select the nodes where the pod will land.
- `openshift_logging_eventrouter_cpu_limit`: The amount of CPU to allocate to eventrouter. Defaults to '100m'.
- `openshift_logging_eventrouter_memory_limit`: The memory limit for eventrouter pods. Defaults to '128Mi'.
- `openshift_logging_eventrouter_namespace`: The namespace where eventrouter is deployed. Defaults to 'default'.

Security Considerations
---
Events should only be visible by users in a cluster admin role.  This means we can store these events in the `.operations.*` indices and/or the OPS cluster. For example, if using the eventrouter as a pod, if it runs in the `default` or `openshift` namespace, the output of that pod will go to the `.operations.* indices`.

Questions & Answers
---
**Q: Why are the kubernetes events collected by eventrouter?**

A: Other known option was to use the fluentd kubernetes input plugin, but it was not in a working state and debugging was time consuming, the plugin maintainer recommended eventrouter. Also the eventrouter is used in another effort that tries to bring Kafka as an alternative for a real time logging analysis.

**Q: What happens when eventrouter dies?**

A: Currently, it gets restarted, reads the event API, and creates duplicates of the few latest events that are still sitting in etcd. We would like to change this behavior to prevent any duplicates in the future.

**Q: Why are the kubernetes events stored in the .operations index?**

A: To simplify the iterative development, we decided that in the first step, eventrouter will be deployed in the default namespace. If there is a desire to group the events by openshift project, eventrouter/fluentd will be modified to satisfy this.

**Q: Does bringing eventrouter create any performance regressions?**

A: Previously, fluentd kubernetes metadata filter plugin created the Hash with metadata only once per chunk of events sharing the tag. Modification of those fields created unwanted propagation to related messages as ruby method Hash::merge creates only shallow copy. Deep copy is achieved via marshall and unmarshall ruby methods.
