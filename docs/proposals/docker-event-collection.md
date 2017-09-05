# Docker Event Collection
## Overview
Docker events are not collected or stored by the Openshift cluster.  Certain customers are [required](https://trello.com/c/qxoFsKz9/) to audit these events (e.g. security).  This document is the architecture and design proposal for gathering Docker events for persistence as log entries interleaved with other operational logs.

## Requirements
### Security 
Docker event log entries shall have the same visibility as other operational log entries.
### Storage and Retention
Docker events shall be stored for the same retention period as other log event messages.  The default curation period is 31 days.  The default indices are the operations indices

# Proposal
Openshift is deployed with [ProjectAtomic Docker](https://github.com/projectatomic/docker/blob/docker-1.12.6/api/server/middleware/audit_linux.go) that enhances audit logging of container events.  These events are logged to the audit file on the node.  The log collector for the logging stack already has access to the file system and will collect docker events from this file.  

**NOTE:** Only Docker Events will be parsed from the audit log; all others will be dropped.

An example event messages written to `/var/log/audit/messages`:

```
type=VIRT_CONTROL msg=audit(1504273220.029:520188): pid=14500 uid=0 auid=4294967295 ses=4294967295 subj=system_u:system_r:container_runtime_t:s0 msg='vm=docker.io/openshift/origin-logging-kibana@sha256:a9d309679
cd8c1b098c696b8acef9fba401c09ed7568ad266eb32208c2ce4da9 user=? auid=4294967295 reason=api op=exec vm-pid=17235 exe=container-entrypoint hostname=logging-kibana-1-xxmr3  exe="/usr/bin/dockerd-current" hostname=? 
addr=? terminal=? res=success'

```

The additional fields:

|Field|Type|Definition| Example |
|----|-----|-|------|
|op| string|The operation or action being performed|exec
|reason | string|The constant value 'api'|api
|vm|string|The docker image of the container|docker.io/openshift/origin-logging-kibana@sha256:a9d309679...
|vm-pid|int|The process id of the running container|17235
|user|string|The username associated with the login id| 
|auid|int64|The login id of the authenticated user |4294967295
|exe|string|The entrypoint to the container|container-entrypoint
|hostname|string|The name of the pod for the container|logging-kibana-1-xxmr3

## Openshift Ansible Modifications
* The `openshift_logging_fluentd` role adds an inventory variable to conditionally include docker event log collection. *Note:* Docker events will, by default, not be collected and will require users to opt in.
* The fluentd DaemonSet is updated to include an additional volumeMount for the audit log:
```
apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  name: logging-fluentd
  ...
  spec:
    containers:
    ...
    - env:
      - name: ENABLE_AUDITLOG_COLLECTION
        value: "true"
    - volumeMounts
        - mountPath: /var/log/audit
          name: auditlog
      volumes:
      - hostPath:
          path: /var/log/audit
        name: auditlog

```

## Common Data Model Modifications
The [CDM](https://github.com/ViaQ/fluent-plugin-viaq_data_model) is updated to perform transformations in ruby code. Fields defined previously are mapped directly into `docker.events` tag like:
```
docker:
  event:
    op: exec
    reason: api
    vm: docker.io/openshift/origin-logging-kibana@sha256:a9d309679...
    vm-pid:  17235
    auid:  4294967295
    exe: container-entrypoint
    hostname: logging-kibana-1-xxmr3
```
## Fluentd Modifications
* Modify fluentd configuration to conditionally include transformation plugin from the CDM

## Dependencies
 * [ProjectAtomic Docker](https://github.com/projectatomic/docker) version 1.12.6 - Docker fork with patch for enhanced auditing

# Alternative Considerations
## Fluentd plugin to connect directly to the docker daemon
This requires the creation of a custom plugin to fluentd to watch docker events.  The watcher can periodically disconnect which requires a reconnect strategy.  This possibly could result in message loss if not properly handled.  Additionally it would add the burden of maintaining and releasing a custom solution.

## Event information present in the docker journal log
The event information present in the journal log does not include enough information to be useful.



