# Fluentd
[Fluentd](https://www.fluentd.org/) is the log collector that resides on each Openshift node to gather application and node logs

## Configuration
Following are the environment variables that can be modified to adjust the configuration:

| Environment Variable | Description |Example|
|----------------------|-------------|---|
| `OCP_OPERATIONS_PROJECTS`| The list of project or patterns for which messages will be sent to the operations indices|`OCP_OPERATIONS_PROJECTS="default openshift openshift-"`

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
