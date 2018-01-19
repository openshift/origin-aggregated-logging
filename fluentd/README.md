# Fluentd
[Fluentd](https://www.fluentd.org/) is the log collector that resides on each Openshift node to gather application and node logs

## Configuration
Following are the environment variables that can be modified to adjust the configuration:

| Environment Variable | Description |Example|
|----------------------|-------------|---|
| `OCP_OPERATIONS_PROJECTS`| The list of project or patterns for which messages will be sent to the operations indices|`OCP_OPERATIONS_PROJECTS="default openshift openshift-"`
