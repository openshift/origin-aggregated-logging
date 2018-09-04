# Curator

[Curator](https://www.elastic.co/guide/en/elasticsearch/client/curator/5.2/about.html) helps you curate, or manage, your Elasticsearch indices and snapshots. This document describes how it's used in OpenShift Origin Aggregated Logging.

The pod runs periodically as a kubernetes cronjob. The time when the job gets started is configurable during [installation](https://github.com/openshift/openshift-ansible/tree/master/roles/openshift_logging#optional-vars) or by changing environment variables of the cronjob. When the pod is started, it will read its configuration from two mounted yaml files:
* [Configuration file](https://www.elastic.co/guide/en/elasticsearch/client/curator/5.2/configfile.html) (`curator5.yaml`) - general config, e.g. elasticsearch hostname, path to certificates etc.
* [OpenShift custom config](#openshift-custom-config) (`config.yaml`) - a simple way how to remove old indices. A curator [actions file](https://www.elastic.co/guide/en/elasticsearch/client/curator/5.2/actionfile.html) is generated based on this config

> Optionally you can use the [actions file](https://www.elastic.co/guide/en/elasticsearch/client/curator/5.2/actionfile.html) (`actions.yaml`) directly. This allows you to use any action that Curator has available to it to be run periodically. However, this is only recommended for advanced users as using this can be destructive to the cluster and can cause removal of required indices/settings from Elasticsearch. To learn more about using the actions file see [Using actions file](#using-actions-file)

### OpenShift custom config
A simple yaml file that is structured like this:
```
PROJECT_NAME:
  ACTION:
    UNIT: VALUE

PROJECT_NAME:
  ACTION:
    UNIT: VALUE
...
```
* PROJECT\_NAME - the actual name of a project - "myapp-devel"
  * For operations logs, use the name `.operations` as the project name
* ACTION - the action to take - currently only "delete"
* UNIT - one of "days", "weeks", or "months"
* VALUE - an integer for the number of units
* `.defaults` - use `.defaults` as the PROJECT\_NAME to set the defaults for
projects that are not specified
* `.regex` - list of regular expressions that match project names
  * `pattern` - valid and properly escaped regular expression pattern
  enclosed by single quotation marks
  * ACTION - the action to take - currently only "delete"
  * UNIT - one of "days", "weeks", or "months"
  * VALUE - an integer for the number of units

### Using regular expressions
User defined regular expressions are checked for their validity
and passed to curator as-is. No further processing like
escaping special characters is done.

*Important*: Enclose regular expressions in single quotation marks (`'`)
as described in [YAML documentation](http://www.yaml.org/spec/1.2/spec.html#style/flow/single-quoted).

Indices in Origin Aggregated Logging are created on a daily basis
with the prefix `project.` and a suffix of the project id and
creation date of the index. Therefore, regular expressions
should conform to this naming scheme `project.name.uuid.yyyy.mm.dd`.

Consider the following indices:
* `project.frontend-dev.2956e294-f602-11e7-b295-0e8b477a338e.2018.01.10`
* `project.backend-dev.cf59add9-f601-11e7-b295-0e8b477a338e.2018.01.10`

These can be matched by a single regular expression `'^project\..+\-dev\..*$'`.

### Example configuration
```
myapp-dev:
  delete:
    days: 1

myapp-qe:
  delete:
    weeks: 1

.operations:
  delete:
    weeks: 8

.defaults:
  delete:
    days: 31

.regex:
  - pattern: '^project\..+\-dev\..*$'
    delete:
      days: 1
  - pattern: '^project\..+\-test\..*$'
    delete:
      days: 2
...
```

Every day, curator will run, and will delete indices in the myapp-dev project
older than 1 day, indices in the myapp-qe project older than 1 week, and
indices older than 2 days that are matched by the `'^project\..+\-test.*$'` and 1 day that are matched by the `'^project\..+\-dev.*$'` regex.
All other projects will have their indices deleted after they are 31 days old
by default.

*WARNING*: Using `months` as the unit

When you use month based trimming, curator starts counting at the _first_ day of
the current month, not the _current_ day of the current month.  For example, if
today is April 15, and you want to delete indices that are 2 months older than
today (`delete: months: 2`), curator doesn't delete indices that are dated
older than February 15, it deletes indices older than _February 1_.  That is,
it goes back to the first day of the current month, _then_ goes back two whole
months from that date.
If you want to be exact with curator, it is best to use `days` e.g. `delete: days: 31`
[Curator issue](https://github.com/elastic/curator/issues/569)

### Compatibility with OpenShift 3.7
In earlier releases admins could control the timezone and time when curator runs from the curator config. This configuration has been moved to openshift-ansible. The [timezone is not currently configurable](https://github.com/kubernetes/kubernetes/issues/47202), instead the timezone of OpenShift master node is used.

### Using actions file
OpenShift custom config file format ensures that important internal indices don't get deleted by mistake. In order to use the actions file add an [exclude](https://www.elastic.co/guide/en/elasticsearch/client/curator/5.2/fe_exclude.html) rule to your configuration to retain these indices. You also need to manually add all the other patterns, see action 3 in the below example:
```
actions:
  1:
    action: delete_indices
    description: be careful!
    filters:
    - exclude: false
      kind: regex
      filtertype: pattern
      value: '^project\.myapp\..*$'
    - direction: older
      filtertype: age
      source: name
      timestring: '%Y.%m.%d'
      unit_count: 7
      unit: days
    options:
      continue_if_exception: false
      timeout_override: '300'
      ignore_empty_list: true
  2:
    action: delete_indices
    description: be careful!
    filters:
    - exclude: false
      kind: regex
      filtertype: pattern
      value: '^\.operations\..*$'
    - direction: older
      filtertype: age
      source: name
      timestring: '%Y.%m.%d'
      unit_count: 56
      unit: days
    options:
      continue_if_exception: false
      timeout_override: '300'
      ignore_empty_list: true
  3:
    action: delete_indices
    description: be careful!
    filters:
    - exclude: true
      kind: regex
      filtertype: pattern
      value: '^project\.myapp\..*$|^\.operations\..*$|^\.searchguard\..*$|^\.kibana$'
    - direction: older
      filtertype: age
      source: name
      timestring: '%Y.%m.%d'
      unit_count: 30
      unit: days
    options:
      continue_if_exception: false
      timeout_override: '300'
      ignore_empty_list: true
```

### Modifying configuration
To create the curator configuration, you can just edit the current
configuration in the deployed configmap:

    $ oc edit configmap/logging-curator

For scripted deployments, copy the configuration file that was created by the installer and create your new OpenShift custom config:
```
$ oc extract configmap/logging-curator --keys=curator5.yaml,config.yaml --to=/my/config
$ edit /my/config/curator5.yaml
$ edit /my/config/config.yaml
$ oc delete configmap logging-curator ; sleep 1
$ oc create configmap logging-curator \
    --from-file=curator5.yaml=/my/config/curator5.yaml \
    --from-file=config.yaml=/my/config/config.yaml \
    ; sleep 1
```
If you're using actions file:
```
$ oc extract configmap/logging-curator --keys=curator5.yaml,actions.yaml --to=/my/config
$ edit /my/config/curator5.yaml
$ edit /my/config/actions.yaml
$ oc delete configmap logging-curator ; sleep 1
$ oc create configmap logging-curator \
    --from-file=curator5.yaml=/my/config/curator5.yaml \
    --from-file=actions.yaml=/my/config/actions.yaml \
    ; sleep 1
```
Next scheduled job will use this configuration.

#### Control cronjob
The `oc` client curently doesn't provide commands for manipulating cronjobs.
Instead use the following commands to controll the cronjob:
```
# suspend cronjob
oc patch cronjob logging-curator -p '{"spec":{"suspend":true}}'

# resume cronjob
oc patch cronjob logging-curator -p '{"spec":{"suspend":false}}

# change cronjob schedule
oc patch cronjob logging-curator -p '{"spec":{"schedule":"0 0 * * *"}}'

# with oc client v3.10 and newer it's possible to manually create jobs from a cronjob
# this
oc create job --from=cronjob/logging-curator <job_name>
```
