# Fluentd
[Fluentd](https://www.fluentd.org/) is the log collector that resides on each Openshift node to gather application and node logs

## Configuration
Following are the environment variables that can be modified to adjust the configuration:

| Environment Variable | Description |Example|
|----------------------|-------------|---|
| `ENABLE_PROMETHEUS_ENDPOINT`| Enable or diable the prometheus endpoint (Default: true)| `ENABLE_PROMETHEUS_ENDPOINT=false`|
| `MERGE_JSON_LOG`     | **DEPRECATED** Parse JSON log messages and merge them into the JSON payload to be indexed to Elasticsearch. **Default:** True | `MERGE_JSON_LOG=true`|
| `OCP_OPERATIONS_PROJECTS`| The list of project or patterns for which messages will be sent to the operations indices|`OCP_OPERATIONS_PROJECTS="default openshift openshift- kube-*"`|
| `LOGGING_FILE_PATH` | The log file absolute path where Fluentd is writting its logs. If you want Fluentd to output its logs as Fluentd does by default (`STDOUT`) set this variable to `console` value. Default value is `/var/log/fluentd/fluentd.log`. | `LOGGING_FILE_PATH=console` |
| `LOGGING_FILE_AGE` | Number of log files that Fluentd keeps before deleting the oldest file. Default value is `10`. | `LOGGING_FILE_AGE=30` |
| `LOGGING_FILE_SIZE` | Maximum size of a Fluentd log file in bytes. If the size of the log file is bigger, the log file gets rotated. Default is 1MB | `LOGGING_FILE_PATH=1024000`

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

## Fluentd logging to file
Fluentd by default writes its logs into a file given by `LOGGING_FILE_PATH` environment variable. You can change the maximum size of a single log file or number of log files to keep(age), by setting `LOGGING_FILE_SIZE` and `LOGGING_FILE_AGE` environment variables accordingly.

If you want Fluentd to output its logs as Fluentd does by default (`STDOUT`) set the `LOGGING_FILE_PATH` variable to `console` value.

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

### logs
Print out the contents of Fluentd log files.

Contents of files stored in the directory where `LOGGING_FILE_PATH` is, are printed out. Starting with the oldest log. Using `-f` option you can follow what is being written into the logs.
The default path where the logs are is `/var/log/fluentd/`, default name of the log file is `fluentd.log`.

## Changes

* 2018-Apr-20 - `merge_json_log` - Introduce variable for deprecating config option. [bug 1569825](https://bugzilla.redhat.com/show_bug.cgi?id=1569825)
