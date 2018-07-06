# Fluentd
[Fluentd](https://www.fluentd.org/) is the log collector that resides on each Openshift node to gather application and node logs

## Configuration
Following are the environment variables that can be modified to adjust the configuration:

| Environment Variable | Description |Example|
|----------------------|-------------|---|
| `MERGE_JSON_LOG`     | **DEPRECATED** Parse JSON log messages and merge them into the JSON payload to be indexed to Elasticsearch. **Default:** True | `MERGE_JSON_LOG=true`|
| `OCP_OPERATIONS_PROJECTS`| The list of project or patterns for which messages will be sent to the operations indices|`OCP_OPERATIONS_PROJECTS="default openshift openshift- kube-*"`

## Cri-o Formatted Container Logs
In order to enable cri-o logs parsing, it is necessary to mount
`node-config.yaml` from the host inside the fluentd container to this path:
```
/etc/origin/node/node-config.yaml
```
If EFK stack is deployed using openshift-ansible 3.9 or later, the mount point
is already created by ansible installer.

Fluentd pod on startup automatically determines from the `node-config.yaml`
whether to setup `in_tail` plugin to parse cri-o formatted logs in
`/var/log/containers/*` or whether to read logs from docker driver.

## Utilities
### sanitize_msg_chunks
Sanitize file buffer chunks by removing corrupt records.

There are known [cases](https://bugzilla.redhat.com/show_bug.cgi?id=1562004) where fluentd is stuck processing
messages that were buffered to corrupt file buffer chunks. This utility is run manually and deserializes each
file chunk, perform a limited set of operations to confirm message validity. Use this utility by:

* Stopping fluentd
* Running the utility
* Restarting fluentd

**Note:** THIS OPERATION IS DESTRUCTIVE; It will rewrite the existing file buffer chunks.  Consider backing up
the files before running this utility.

## Changes

* 2018-Apr-20 - `merge_json_log` - Introduce variable for deprecating config option. [bug 1569825](https://bugzilla.redhat.com/show_bug.cgi?id=1569825)
