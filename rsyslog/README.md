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

## Rsyslog logging to file
Rsyslog by default writes its logs into a file given by `LOGGING_FILE_PATH` environment variable. You can change the maximum size of a single log file or number of log files to keep(age), by setting `LOGGING_FILE_SIZE` and `LOGGING_FILE_AGE` environment variables accordingly.

If you want Rsyslog to output its logs as Rsyslog does by default (`STDOUT`) set the `LOGGING_FILE_PATH` variable to `console` value.

## Utilities
### logs
Print out the contents of Rsyslog log files.

Contents of files stored in the directory where `LOGGING_FILE_PATH` is, are printed out. Starting with the oldest log. Using `-f` option you can follow what is being written into the logs.
The default path where the logs are is `/var/log/rsyslog/`, default name of the log file is `rsyslog.log`.

