# Sending logs to a remote syslog

The fluent-plugin-remote-syslog gem is used to send collected logs to remote syslog servers over **unsecured** UDP/TCP.

This implementation is insecure, and should only be used in environments where you can guarantee no snooping on the connection.


## Configuration
The plugin can be configured by setting environment variables, or configuring your own fluent.conf in the ConfigMap.  
When using environment variables, the REMOTE_SYSLOG_HOST is the only required field.

If multiple syslog destinations are needed, create a copy of the configuration parameters and append a suffix to the names.
All environment variables that begin with "REMOTE_SYSLOG" are looked at to build the remote syslog configuration file.

For example:
```yaml
- name: REMOTE_SYSLOG_HOST
  value: host1
- name: REMOTE_SYSLOG_HOST_BACKUP
  value: host2
- name: REMOTE_SYSLOG_PORT_BACKUP
  value: 5555
```
The above will build two destinations.  The syslog server on host1 will be receiving messages on the default port of 514, 
while host2 will be receiving the same messages on port 5555.

At minimum, each additional host must define the REMOTE_SYSLOG_HOST\*\* environment variable.

USE_REMOTE_SYSLOG **MUST** be set to true regardless of which approach you choose to use if you want to use this plugin.


## Environment Variables
* `USE_REMOTE_SYSLOG` : defaults to false.  Set to true to enable use of the fluent-plugin-remote-syslog gem
* `REMOTE_SYSLOG_HOST` : hostname or ip address of the remote syslog server, this is mandatory
* `REMOTE_SYSLOG_PORT` : port number to connect on, defaults to 514
* `REMOTE_SYSLOG_SEVERITY` : set the syslog severity level, defaults to debug
* `REMOTE_SYSLOG_FACILITY` : set the syslog facility, defaults to local0
* `REMOTE_SYSLOG_USE_RECORD` : defaults to false.  Set to true to use the record's severity and facility fields to set on the syslog message
* `REMOTE_SYSLOG_REMOTE_TAG_PREFIX` : removes the prefix from the tag, defaults to ''
* `REMOTE_SYSLOG_TAG_KEY` : if specified, uses this field as the key to look on the record, to set the tag on the syslog message
* `REMOTE_SYSLOG_PAYLOAD_KEY` : if specified, uses this field as the key to look on the record, to set the payload on the syslog message
