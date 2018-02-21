Introduction
============

When Fluentd is collecting node logs, the main sources are the system logs from
the journal, and container logs, the source of which depends on the `docker
--log-driver` configuration and container runtime selection configured in
`/etc/origin/node/node-config.yaml` mounted to fluentd container from host:

* `journald` - container logs are written to the journal and denoted with the
  `CONTAINER_NAME` field
* `json-file` - container logs are made available in `/var/log/containers`
  (through a long a complicated process of several layers of symlinks).
* `cri-o` - container logs are made available in `/var/log/containers` similarly
  to the `json-file` log driver but with cri-o format

Fluentd will always read system logs from the journal, and will always read
container logs from `journald` or `/var/log/containers`, latter formatted either
as `json` or `cri-o`.

### JSON file container log parameters ###

These are provided for documentation purposes only.  Do not set these unless
you know what you are doing.

* `JSON_FILE_PATH` - default `/var/log/containers/*.log` - full path and filename
match pattern for docker json-file log driver logs
* `JSON_FILE_POS_FILE` - default `/var/log/es-containers.log.pos` - full path
and filename for the Fluentd `in_tail` position file.  This file should be on a
persistent volume (e.g. bind mounted from the host) so that Fluentd can resume
reading from where it left off if the Fluentd pod is restarted.
* `JSON_FILE_READ_FROM_HEAD` - default `true` - if `false`, start reading from
the tail/end of the file.  If the `JSON_FILE_POS_FILE` exists and has an
entry for this file, the `JSON_FILE_READ_FROM_HEAD` setting is ignored.

### cri-o container log parameters ###

Just like the json-file, these are provided for documentation purposes only.
Do not set these unless you know what you are doing.

* `CRIO_FILE_PATH` - default `/var/log/containers/*.log` - full path and filename
match pattern for cri-o file log driver logs
* `CRIO_FILE_POS_FILE` - default `/var/log/es-containers.log.pos` - full path
and filename for the Fluentd `in_tail` position file.  This file should be on a
persistent volume (e.g. bind mounted from the host) so that Fluentd can resume
reading from where it left off if the Fluentd pod is restarted.
* `CRIO_FILE_READ_FROM_HEAD` - default `true` - if `false`, start reading from
the tail/end of the file.  If the `CRIO_FILE_POS_FILE` exists and has an
entry for this file, the `CRIO_FILE_READ_FROM_HEAD` setting is ignored.

### journal parameters ###

These are provided for documentation purposes only.  Do not set these unless
you know what you are doing.

* `JOURNAL_SOURCE` - no default - Fluentd will attempt to use
`/var/log/journal` if it exists, otherwise, it will fall back on
`/run/log/journal`.
* `JOURNAL_POS_FILE` - default `/var/log/journal.pos` - full path
and filename for the Fluentd `in_systemd` position file.  This file should be on a
persistent volume (e.g. bind mounted from the host) so that Fluentd can resume
reading from where it left off if the Fluentd pod is restarted.
* `JOURNAL_READ_FROM_HEAD` - default `false` - if `false`, start reading from
the tail/end of the journal.  If the `JOURNAL_POS_FILE` exists, the
`JOURNAL_READ_FROM_HEAD` setting is ignored.  **WARNING** if this is set to
`true`, it may take hours, if not longer, until Fluentd reaches the end of the
journal, so be aware that it may take long time for recent records to show up
in Elasticsearch.
* `JOURNAL_FILTERS_JSON` - default `[]` - see
[systemd filter](http://www.rubydoc.info/gems/systemd-journal/Systemd%2FJournal%2FFilterable%3Afilter)
documentation for more information.

### Log throttling ###

Log throttling currently only works for container logs read by the Fluentd
`in_tail` input, from files written by the docker `json-file` log driver.  It
relies on the
(`read_lines_limit`)[https://docs.fluentd.org/v0.12/articles/in_tail#readlineslimit]
feature to make Fluentd read one or a few lines at a time rather than the
default `1000`.  It also relies on the fact that the JSON log files in
`/var/log/containers` have names in the following format:
`/var/log/containers/POD-NAME_NAMESPACE-NAME_CONTAINER-NAME-CONTAINER-ID.log`
That is, the name of the namespace to be throttled can be matched by the
pattern `/var/log/containers/*_NAMESPACE-NAME_*.log`.  If this name format
changes, throttling will not work.

To configure log throttling:

Edit the logging-fluentd configmap - the `throttle-config.yaml` setting:

    PROJECT-NAME:
      read_lines_limit: NUMBER
    ANOTHER-PROJECT-NAME:
      read_lines_limit: ANOTHER-NUMBER

Where `PROJECT-NAME` is the name of the project whose logs you want to
throttle, and `NUMBER` is the number of lines to read at a time.  The default
is `1000`.  A lower number means more throttling.  `1` is the minimum.
