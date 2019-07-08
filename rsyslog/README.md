# rsyslog-container
[Rsyslog](https://www.rsyslog.com/) is the log collector that resides on each Openshift node to gather application and node logs

## Configuration
Following are the environment variables that can be modified to adjust the configuration:

| Environment Variable | Description |Example|
|----------------------|-------------|---|
| `MERGE_JSON_LOG`     | **DEPRECATED** Parse JSON log messages and merge them into the JSON payload to be indexed to Elasticsearch. **Default:** false | `MERGE_JSON_LOG=true`|
| `LOGGING_FILE_PATH` | The log file absolute path where Rsyslog is writting its logs. If you want rsyslog to output its logs as Rsyslog does by default (`STDOUT`) set this variable to `console` value. Default value is `/var/log/rsyslog/rsyslog.log`. | `LOGGING_FILE_PATH=console` |
| `LOGGING_FILE_AGE` | Number of log files that Rsyslog keeps before deleting the oldest file. Default value is `10`. | `LOGGING_FILE_AGE=30` |
| `LOGGING_FILE_SIZE` | Maximum size of a rsyslog log file in bytes. If the size of the log file is bigger, the log file gets rotated. Default is 1MB | `LOGGING_FILE_SIZE=1024000`
| `USE_MMEXTERNAL` | Parameter to switch whether mmexternal undefined_field is called or not. default to "false" if CDM parameters are not configured; "true" otherwise.  | `USE_MMEXTERNAL=true`
| `SKIP_EMPTY` | Parameter to switch whether mmnormalize skip-empty is called or not. default to "true" if CDM parameters are not configured; "false" otherwise. | `SKIP_EMPTY=false`
| `CDM_USE_UNDEFINED` | Parameter to switch whether undefined fields are moved to the undefined property or not. default to "false". | `CDM_USE_UNDEFINED=true`
| `CDM_DEFAULT_KEEP_FIELDS` | Default set of fields to be kept in the top level of json.  default to "CEE,time,@timestamp,aushape,ci_job,collectd,docker,fedora-ci,file,foreman,geoip,hostname,ipaddr4,ipaddr6,kubernetes,level,message,namespace_name,namespace_uuid,offset,openstack,ovirt,pid,pipeline_metadata,rsyslog,service,systemd,tags,testcase,tlog,viaq_msg_id",  | -
| `CDM_EXTRA_KEEP_FIELDS` | Extra set of fields to be kept in the top level of json.  A field not included in ${CDM_DEFAULT_KEEP_FIELDS} nor ${CDM_EXTRA_KEEP_FIELDS} are moved to ${CDM_UNDEFINED_NAME} if CDM_USE_UNDEFINED is "true". default to "" | `CDM_EXTRA_KEEP_FIELDS="broker"` 
| `CDM_UNDEFINED_NAME` | Undefined property name used when CDM_USE_UNDEFINED is set to "true". default to "undefined". | `CDM_UNDEFINED_NAME="undef"`
| `CDM_KEEP_EMPTY_FIELDS` | Empty fields are dropped except the fields which names are set to CDM_KEEP_EMPTY_FIELDS in the CSV format. default to "". | `CDM_KEEP_EMPTY_FIELDS="offset"`
| `CDM_UNDEFINED_TO_STRING` | If set to "true", when CDM_USE_UNDEFINED is "true" and undefined property with ${CDM_UNDEFINED_NAME} is created, the value is converted to the json string. default to "false". | `CDM_UNDEFINED_TO_STRING=true
| `CDM_UNDEFINED_DOT_REPLACE_CHAR` | A dot character '.' in a property name (key) is replaced with the specified character unless the value is not "UNUSED". default to "UNUSED". Effective when MERGE_JSON_LOG is true. | `CDM_UNDEFINED_DOT_REPLACE_CHAR="_"`
| `CDM_UNDEFINED_MAX_NUM_FIELDS` | If set to a number greater than -1, and if the number of undefined fields is greater than this number, all of the undefined fields will be converted to their JSON string representation and stored in the undefined_name named field. default to "-1" although not recommended. | `CDM_UNDEFINED_MAX_NUM_FIELDS=2`
| `UNDEFINED_DEBUG` | Debug flag used in undefined_field as well as the config file calling the plugin.  A debug file /var/log/rsyslog/rsyslog_debug.log is generated.  default to "false". | `UNDEFINED_DEBUG=true`

## Rsyslog logging to file
Rsyslog by default writes its logs into a file given by `LOGGING_FILE_PATH` environment variable. You can change the maximum size of a single log file or number of log files to keep(age), by setting `LOGGING_FILE_SIZE` and `LOGGING_FILE_AGE` environment variables accordingly.

If you want Rsyslog to output its logs as Rsyslog does by default (`STDOUT`) set the `LOGGING_FILE_PATH` variable to `console` value.

## Utilities
### logs
Print out the contents of Rsyslog log files.

Contents of files stored in the directory where `LOGGING_FILE_PATH` is, are printed out. Starting with the oldest log. Using `-f` option you can follow what is being written into the logs.
The default path where the logs are is `/var/log/rsyslog/`, default name of the log file is `rsyslog.log`.

# Hacking

## Updating rsyslog_exporter

Once the source code has been updated, and the file `rsyslog/rsyslog_exporter.source`, update deps:
```
cd rsyslog/go/src/github.com/soundcloud/rsyslog_exporter
GOPATH=/path/to/origin-aggregated-logging/rsyslog/go dep ensure -update
```
