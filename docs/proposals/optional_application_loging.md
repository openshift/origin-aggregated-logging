Optional Application Logging
============================

The EFK aggregated logging stack collects application logs from STDOUT of 
containers managed by OpenShift. Currently, container logs are collected only on 
those nodes where fluentd pod is deployed. This can be controlled via node label 
and ansible variable `openshift_logging_fluentd_nodeselector` as described in the
[documentation](https://docs.openshift.org/latest/install_config/aggregate_logging.html)
during the logging deployment.

This proposal discusses some ways of a finer grained level of control over what 
container logs are processed and stored using the EFK stack.

## Fluentd pipeline

The container logs can be obtained from one of these supported logging drivers
- `json-file` - logs read from `/var/log/containers/*` mounted in fluentd
              container
- `journald`

Latest development shifted recommended docker driver from `journald` to `json-file`,
therefore, the proposed implementation has focused on usage of `json-file` as
well. Rationale being, `journald` currently doesn't match performance expectations
and desired throttling control for larger clusters.

Each container on the host has its own json structured log file
- `/var/log/containers/[pod]_[namespace]_[container]-[docker_id].log`

Every line is treated as a separate log message and processed in the cascade
of fluentd filters. A log line doesn't contain OpenShift metadata, this is 
added to the message in the fluentd `k8_metadata_filter` plugin.

#### Dynamic Control of Optional Logging

By 'dynamic control' we understand the ability of an operator or a user to
opt-in or opt-out certain OpenShift object (further proposed prototype discusses 
pods and namespace exclusion) from aggregated logging without having to redeploy 
fluentd. This approach has immediate effect, offers very granular level of control, 
is flexible, and a change of settings in order to disable logging on a particular 
container doesn't introduce a spike in latency for other containers logs.

It requires additional resources:
- memory - cache `O(count(namespaces)+count(pods))` + process overhead
- CPU - parsing notices + process overhead

and also brings overhead to the API server, where the fluentd input plugin has 
to `watch` `namespaces` and `pods` API endpoints.

Following solution describes how this can be implemented as an opt-out strategy:
- a user annotates a namespace or a pod with `io.openshift.logging_opt_out=true`
    - for example using `oc annotate pod [pod] io.openshift.logging_opt_out=true`
- the fluentd will exclude log files based on this information
- removing the annotation `io.openshift.logging_opt_out` or setting it to any other
  value resumes the log collection from the moment, where it was paused
![fluentd optin pipeline](https://raw.githubusercontent.com/wozniakjan/origin-aggregated-logging/proposal/optional_logging/docs/proposals/optin_pipeline.png)

One way how to achieve this could be creating additional layer of symlinks to
the log files. Currently the log files in `/var/log/containers/` are symlinks
to files in `/var/log/pods/`, those are symlinks to files in `/var/lib/docker/containers/`,
and finally those are UTF-8 formatted text files. We could create symlinks to
`/var/log/containers/*` in a different directory, `/var/log/containers/optin/*`
for instance. Then a daemon watching the OpenShift APIs and keep the symlinks
in `/var/log/containers/optin/*` up to date.

```
monitored layer of symlinks                original layers of symlinks                UTF-8 text files
           |                                   /                  \                          |
           V                                  V                    V                         V
/var/log/containers/optin/*  ->  /var/log/containers/*  ->  /var/log/pods/*  ->  /var/lib/docker/containers/*
```

Second approach, vendoring custom changes in fluentd `in_tail` plugin is
described in this implementation of a working prototype:
- https://github.com/wozniakjan/origin-aggregated-logging/pull/2

Fluentd `in_tail` plugin changes:
- watch `/api/v1/namespaces` and `/api/v1/pods`
- cache pod and namespace annotation `io.openshift.logging_opt_out`
- on notice, asynchronously call `refresh_watchers`
  - otherwise would have to wait for a [`refresh_interval`](https://docs.fluentd.org/v0.12/articles/in_tail#refresh_interval)
- in `expand_paths` filter out files matching cached notices

#### Explicit Optional Logging

Users and cluster operators would have to create an agreed precondition upon
which logging will be gathered. Any change to the existing setup will require
an action from a cluster operator and redeployment of fluentd container, 
therefore, change of settings introduces a spike in latency for other containers
as well.

This approach could be achieved using [`exclude_path`](https://docs.fluentd.org/v0.12/articles/in_tail#exclude_path)
configuration option of fluentd tail plugin. This would bring no overhead to
the OpenShift API server, offers similar granularity of control as dynamic
optional logging but introduces delay to all messages every time a change has
to be made and can be enforced only by cluster operators.

Following steps can reproduce the above described behavior:
- have the EFK aggregated logging deployed
- modify `generate_throttle_configs.rb` to exclude desired pod with 
  `exclude_path` in the `in_tail` plugin config in
  ```
  <source> 
    @type tail 
    @label @INGRESS 
    path "#{ENV['JSON_FILE_PATH'] || '/var/log/containers/*.log'}" 
    pos_file "#{ENV['JSON_FILE_POS_FILE'] || '/var/log/es-containers.log.pos'}" 
    time_format %Y-%m-%dT%H:%M:%S.%N%Z 
    tag kubernetes.* 
    format json 
    keep_time_key true 
    read_from_head "#{ENV['JSON_FILE_READ_FROM_HEAD'] || 'true'}" 
    exclude_path #{excluded} 
  </source> 
  ```
- rebuild and redeploy fluentd image

## Comparison

There are multiple criteria worth addressing, following discusses some
advantages and disadvantages.

#### Opt-in vs. Opt-out

|         | requires changes                  | collect logs by default | upgrade scenario          |
|---------|-----------------------------------|-------------------------|---------------------------|
|Opt-in   | openshift-ansible, fluentd image  | no                      | needs preliminary steps\* |
|Opt-out  | fluentd image                     | yes                     | works by default          |

\* given opt-in requires changes in both openshift-ansible and fluentd image and
   we can not guarantee user will have both versions appropriately synchronized,
   as an insurance, it will be best to manually annotate all desired OpenShift 
   objects as opted-in before updating the fluentd image

#### Dynamic vs. Explicit

|         | level of control | downtime on upgrade | code changes        | effect        |
|---------|------------------|---------------------|---------------------|---------------|
|Dynamic  | pod / namespace  | no                  | needs maintenance   | immediate     |
|Explicit | pod / namespace  | yes                 | trivial             | on ops action |


