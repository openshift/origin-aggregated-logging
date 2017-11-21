# Aggregated Logging Utilities

 ## logging-dump
`logging-dump.sh` is a tool to gather as much information as possible from your logging cluster. In order to run the script, the user must be logged in and have a administrative permissions on project `logging`

Usage:
```
$ oc login -u admin https://openshift.example.com:8443
$./logging-dump.sh [<component1> ... <componentN>]
```

Components:
* kibana
* elasticsearch
* curator
* fluentd

Examples:
* Get information from the nodes, project and all logging components

`$ ./logging-dump.sh`

* Get information only from elasticsearch and kibana componentes

`$ ./logging-dump.sh elasticsearch kibana`

* Resulting folder structure
```
└── logging-<yyyyMMdd_HHmmss>
    ├── fluentd
    │   ├── logs
    │   │   ├── <logging-fluentd-pod-1>.log.xz
    │   │   ├── ...
    │   │   └── <logging-fluentd-pod-N>.log.xz
    │   ├── <logging-fluentd-pod-1>
    │   ├── ...
    │   └── <logging-fluentd-pod-N>
    ├── kibana
    │   ├── logs
    │   │   ├── <logging-kibana-pod>-kibana.log.xz
    │   │   ├── <logging-kibana-pod>-kibana-proxy.log.xz
    │   │   ├── <logging-kibana-ops-pod>-kibana.log.xz
    │   │   └── <logging-kibana-ops-pod>-kibana-proxy.log.xz
    │   ├── <logging-kibana-pod>-kibana
    │   └── <logging-kibana-pod>-kibana-proxy
    │   ├── <logging-kibana-ops-pod>-kibana
    │   └── <logging-kibana-ops-pod>-kibana-proxy
    ├── es
    │   ├── cluster-es
    |   │   ├── aliases
    |   │   ├── health
    |   │   ├── indices
    |   │   ├── latest_documents.json
    |   │   ├── nodes
    |   │   ├── nodes_stats
    |   │   ├── thread_pool    
    |   │   ├── pending_tasks
    |   │   ├── recovery
    |   │   ├── shards
    |   │   └── unassigned_shards
    │   ├── cluster-es-ops
    |   │   ├── aliases
    |   │   ├── health
    |   │   ├── indices
    |   │   ├── latest_documents.json
    |   │   ├── nodes
    |   │   ├── nodes_stats
    |   │   ├── thread_pool
    |   │   ├── pending_tasks
    |   │   ├── recovery
    |   │   ├── shards
    |   │   └── unassigned_shards
    │   ├── logs
    │   │   ├── <logging-es-pod-1>/logging-es_deprecation.log.xz
    │   │   ├── <logging-es-pod-1>/logging-es_indexing_slowlog.log.xz
    │   │   ├── <logging-es-pod-1>/logging-es_search_slowlog.log.xz
    │   │   ├── <logging-es-pod-1>/logging-es.log.xz
    │   │   ├── <logging-es-pod-1>.log.xz
    │   │   ├── ...
    │   │   ├── <logging-es-ops-pod-1>.log.xz
    │   │   └── ...
    │   ├── <logging-es-pod-1>
    │   └── ...
    │   ├── <logging-es-ops-pod-1>
    │   └── ...
    ├── curator
    │   ├── logs
    │   │   ├── <logging-curator-pod>.log.xz
    │   │   └── <logging-curator-ops-pod>.log.xz
    │   ├── <logging-curator-pod>
    │   └── <logging-curator-ops-pod>
    └── project
        ├── configmaps
        │   ├── ... # Configmaps
        ├── daemonsets
        │   ├── ... # Daemonsets
        ├── deploymentconfigs
        │   ├── ... # DeploymentConfigs
        ├── pods
        │   ├── ... # Pods
        ├── pvs
        │   ├── ... # Persistent Volumes
        ├── pvcs
        │   ├── ... # Persistent Volume Claims
        ├── routes
        │   ├── ... # Routes
        ├── services
        │   ├── ... # Services
        ├── serviceaccounts
        │   ├── ... # Service Accounts
        ├── events
        ├── logging-project
        ├── nodes
        └── secrets
```


### Common
* Nodes description `oc describe nodes`
* Project `oc get project logging -o yaml`
* Pod Logs compressed. Use `find . -name "*.xz" | while read filename; do xz -d $filename; done`
* Docker image version `/root/buildinfo/Dockerfile-openshift3*`
* Environment variables
* Pod description
* Deploymentconfigs
* ServiceAccounts
* Configmaps
* Services
* Routes
* Persitent Volumes
* Secrets (Only the name of the files included, not its content)

### Fluentd
* Connectivity with Elasticsearch Service
* If filebuffer is used the available storage and current files will be listed

### Curator
* Connectivity with Elasticsearch Service

### Kibana
* Connectivity with Elasticsearch Servicewith Elasticsearch Service
* Kibana-Proxy oauth-secret `//TODO`

### Elasticsearch
* Cluster health `/_cat/health?v`
* Nodes and memory usage `/_cat/nodes?v`
* Indices `/_cat/indices?v`
* Aliases `/_cat/aliases?v`
* Check 0/1 node folders
* Elasticsearch internal log files
* Latest documents persisted
* Nodes status. Shows thorough information about OS, JVM, Filesystem, etc. [More info](https://www.elastic.co/guide/en/elasticsearch/reference/current/cluster-nodes-stats.html)
* Conditional based on cluster health
  * Pending tasks `/_cluster/pending_tasks`
  * Recovery status `/_cat/recovery`
  * Indices health `/_cat/health?level=indices`
  * Unassigned Shards `/_cat/shards?h=index,shard,prirep,state,unassigned.reason,unassigned.description | grep UNASSIGNED`
