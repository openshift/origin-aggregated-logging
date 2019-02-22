# Release Notes
## 4.0

* [cluster-logging-operator](https://github.com/openshift/cluster-logging-operator) replaces [openshift-ansible](https://github.com/openshift/openshift-ansible) for deploying cluster logging.
* [MERGE_JSON_LOG](https://github.com/openshift/origin-aggregated-logging/issues/1492) default changed to `false`
* Distinct Elasticsearch clusters for separately aggregate application and operations logs is no longer supported.
* [Default kibana.index_mode](https://github.com/openshift/origin-aggregated-logging/issues/1274) to `shared_ops`
* EventRouter requires manual [deployment](./deploy-event-router.md) to collect Kubernetes Events
