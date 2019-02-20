# Fluentd
[Fluentd](https://www.fluentd.org/) is the log collector that resides on each Openshift node to gather application and node logs

## Configuration
Following are the environment variables that can be modified to adjust the configuration:

| Environment Variable | Description |Example|
|----------------------|-------------|---|
| `MERGE_JSON_LOG`     | **DEPRECATED** Parse JSON log messages and merge them into the JSON payload to be indexed to Elasticsearch. **Default:** True | `MERGE_JSON_LOG=true`|
| `OCP_OPERATIONS_PROJECTS`| The list of project or patterns for which messages will be sent to the operations indices|`OCP_OPERATIONS_PROJECTS="default openshift openshift-"`|
| `LOGGING_FILE_PATH` | The log file absolute path where Fluentd is writting its logs. If you want Fluentd to output its logs as Fluentd does by default (`STDOUT`) set this variable to `console` value. Default value is `/var/log/fluentd/fluentd.log`. | `LOGGING_FILE_PATH=console` |
| `LOGGING_FILE_AGE` | Number of log files that Fluentd keeps before deleting the oldest file. Default value is `10`. | `LOGGING_FILE_AGE=30` |
| `LOGGING_FILE_SIZE` | Maximum size of a Fluentd log file in bytes. If the size of the log file is bigger, the log file gets rotated. Default is 1MB | `LOGGING_FILE_PATH=1024000`
| `CDM_UNDEFINED_TO_STRING` | When `MERGE_JSON_LOG=true` - see below (Default: false) | `CDM_UNDEFINED_TO_STRING=true` |
| `CDM_UNDEFINED_DOT_REPLACE_CHAR` | When `MERGE_JSON_LOG=true` - see below (Default: UNUSED) | `CDM_UNDEFINED_DOT_REPLACE_CHAR=_` |
| `CDM_UNDEFINED_MAX_NUM_FIELDS` | When `MERGE_JSON_LOG=true` - see below (Default: -1) | `CDM_UNDEFINED_MAX_NUM_FIELDS=500` |

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

## MERGE_JSON_LOG and undefined field handling

For background information, see [viaq filter plugin docs](https://github.com/ViaQ/fluent-plugin-viaq_data_model#undefined_to_string)
Using `MERGE_JSON_LOG=true` is problematic in a number of ways.
One of the problems with storing data in Elasticsearch is that it really requires you to have strict control over the fields and the number of fields being stored. You typically have to define a strict input pipeline for formatting the data, and define index templates to specify the type of data. If you are dealing with unstructured data, you run into the risk that you have a field named fieldname which in some records has a string value, but in other documents may have an int value or a value of some other data type.  Using `CDM_UNDEFINED_TO_STRING=true` will
force all undefined fields to have a string value (their JSON string interpretation) so that no conflicts like this may arise.  The default
value is `false`, so if you have this problem, set the value to `true`.

Another problem with storing data in Elasticsearch is that it will interpret a field name like "foo.bar" to mean a Hash (Object type in Elasticsearch).  This causes problems if the application emits logs with a string valued field "foo", and a hash valued field "foo.bar". The only way to automatically solve this problem is by converting "foo.bar" to be "foo_bar", and using `CDM_UNDEFINED_DOT_REPLACE_CHAR=_` to convert both values to string.  The default value is `UNUSED` which means `foo.bar` is kept, so if you have this problem, set the value to `_` or some
other "safe" value.

Another problem with storing data in Elasticsearch is that there is an upper limit to the number of fields it can store without causing performance problems. `CDM_UNDEFINED_MAX_NUM_FIELDS` is used to set an upper bound on the number of undefined fields in a single record. If the record contains more than this many undefined fields, no further processing will take place on these fields. Instead, the fields will be converted to a single string JSON value, and will be stored in a top level field named with the value of the `CDM_UNDEFINED_NAME` parameter (default "undefined").  The default value is `-1`, which means all fields are kept, so if you have this problem, set the value to `500`, or
a smaller number if you know exactly how many fields your application logs will produce.

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
