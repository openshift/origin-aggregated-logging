# About the Logging Components

The aggregated logging subsystem consists of multiple components commonly
abbreviated as the "ELK" stack (though modified here to be the "EFK"
stack).

### ElasticSearch

ElasticSearch is a Lucene-based indexing object store into which logs
are fed. Logs for node services and all containers in the cluster are
fed into one deployed cluster. The ElasticSearch cluster should be deployed
with redundancy and persistent storage for scale and high availability.

### Fluentd

Fluentd is responsible for gathering log entries from all nodes, enriching
them with metadata, and feeding them into the ElasticSearch cluster.

### Kibana

Kibana presents a web UI for browsing and visualizing logs in ElasticSearch.

### Logging auth proxy

In order to authenticate the Kibana user against OpenShift's Oauth2 for
single sign-on, a proxy is required that runs in front of Kibana.

### Curator

Curator allows the admin to remove old data from Elasticsearch on a per-project
basis.

### Deployer

The deployer enables the system administrator to generate all of the
necessary key/certs/secrets and deploy all of the logging components
in concert.

# Contents

* [Using the Logging Deployer](#using-the-logging-deployer)
  * [Preparation](#preparation)
  * [Specify Deployer Parameters](#specify-deployer-parameters)
  * [Run the Deployer](#run-the-deployer)
  * [Adjusting the Deployment](#adjusting-the-deployment)
    * [Elasticsearch](#elasticsearch-1)
    * [Fluentd](#fluentd-1)
    * [Kibana](#kibana-1)
    * [Curator](#curator-1)
    * [About the Deployer-Generated Secrets](#about-the-deployer-generated-secrets)
  * [Upgrading your EFK stack](#upgrading-your-efk-stack)
  * [Uninstall and Reinstall](#uninstall-and-reinstall)
* [Using Kibana](#using-kibana)
* [Adjusting ElasticSearch After Deployment](#adjusting-elasticsearch-after-deployment)
* [Checking EFK Health]()
* [Troubleshooting](#troubleshooting)

# Using the Logging Deployer

The deployer pod can enable deploying the full stack of the aggregated
logging solution with just a few prerequisites:

1. Sufficient volumes defined for ElasticSearch cluster storage.
2. A router deployment for serving cluster-defined routes for Kibana.

The deployer generates all the necessary certs/keys/etc for cluster
communication and defines secrets and templates for all of the necessary
API objects to implement aggregated logging. There are a few
manual steps you must run with cluster-admin privileges.

## Preparation

### Choose a Project

You will likely want to put all logging-related entities in their own project.
For examples in this document we will assume the `logging` project.

    $ oadm new-project logging --node-selector=""
    $ oc project logging

You can use the `default` or another project if you want. This
implementation has no need to run in any specific project.

### Create missing templates

If your installation did not create templates in the `openshift`
namespace, the `logging-deployer-template` and `logging-deployer-account-template`
templates may not exist. In that case you can create them with the following:

    $ oc apply -n openshift -f https://raw.githubusercontent.com/openshift/origin-aggregated-logging/master/deployer/deployer.yaml

### Create Supporting Service Accounts and Permissions

The deployer must run under a service account defined as follows:
(Note: change `:logging:` below to match the project name.)

    $ oc new-app logging-deployer-account-template
    $ oadm policy add-cluster-role-to-user oauth-editor \
              system:serviceaccount:logging:logging-deployer

The policy manipulation is required in order for the deployer pod to
create an OAuthClient for Kibana to authenticate against the master,
normally a cluster-admin privilege.

The fluentd component also requires special privileges for its service
account. Run the following command to add the aggregated-logging-fluentd
service account to the privileged SCC (to allow it to mount system logs)
and give it the `cluster-reader` role to allow it to read labels from
all pods (note, change `:logging:` below to the project of your choice):

    $ oadm policy add-scc-to-user privileged \
           system:serviceaccount:logging:aggregated-logging-fluentd
    $ oadm policy add-cluster-role-to-user cluster-reader \
           system:serviceaccount:logging:aggregated-logging-fluentd

The remaining steps do not require cluster-admin privileges to run.

## Specify Deployer Parameters

Parameters for the EFK deployment may be specified in the form of a
`[ConfigMap](https://docs.openshift.org/latest/dev_guide/configmaps.html)`,
a `[Secret](https://docs.openshift.org/latest/dev_guide/secrets.html)`,
or template parameters (which are passed as environment variables). The
deployer looks for each value first in a `logging-deployer` ConfigMap,
then a `logging-deployer` Secret, then as an environment variable. Any
or all may be omitted if not needed.

### Create Deployer ConfigMap

You will need to specify the hostname at which Kibana should be
exposed to client browsers, and also the master URL where client
browsers will be directed for authenticating to OpenShift. You should
read the [ElasticSearch](#elasticsearch) section below before choosing
ElasticSearch parameters for the deployer. These and other parameters
are available:

* `kibana-hostname`: External hostname where web clients will reach Kibana
* `public-master-url`: External URL for the master, for OAuth purposes
* `es-cluster-size`: How many instances of ElasticSearch to deploy. At least 3 are needed for redundancy, and more can be used for scaling.
* `es-instance-ram`: Amount of RAM to reserve per ElasticSearch instance (e.g. 1024M, 2G). Defaults to 8GiB; must be at least 512M (Ref.: [ElasticSearch documentation](https://www.elastic.co/guide/en/elasticsearch/guide/current/hardware.html#_memory).
* `es-pvc-size`: Size of the PersistentVolumeClaim to create per ElasticSearch ops instance, e.g. 100G. If empty, no PVCs will be created and emptyDir volumes are used instead.
* `es-pvc-prefix`: Prefix for the names of PersistentVolumeClaims to be created; a number will be appended per instance. If they don't already exist, they will be created with size `es-pvc-size`.
* `es-pvc-dynamic`: Set to `true` to have created PersistentVolumeClaims annotated such that their backing storage can be dynamically provisioned (if that is available for your cluster).
* `storage-group`: Number of a supplemental group ID for access to Elasticsearch storage volumes; backing volumes should allow access by this group ID (defaults to 65534).
* `fluentd-nodeselector`: The nodeSelector to use for the Fluentd DaemonSet. Defaults to "logging-infra-fluentd=true".
* `es-nodeselector`: Specify the nodeSelector that Elasticsearch should use (label=value)
* `kibana-nodeselector`: Specify the nodeSelector that Kibana should use (label=value)
* `curator-nodeselector`: Specify the nodeSelector that Curator should use (label=value)
* `enable-ops-cluster`: If "true", configure a second ES cluster and Kibana for ops logs. (See [below](#ops-cluster) for details.)
* `kibana-ops-hostname`, `es-ops-instance-ram`, `es-ops-pvc-size`, `es-ops-pvc-prefix`, `es-ops-cluster-size`, `es-ops-nodeselector`, `kibana-ops-nodeselector`, `curator-ops-nodeselector`: Parallel parameters for the ops log cluster.
* `image-pull-secret`: Specify the name of an existing pull secret to be used for pulling component images from an authenticated registry.
* `use-journal`: By default, fluentd will use `/var/log/messages*` and
`/var/log/containers/*.log` for system logs and container logs, respectively.
Setting `use-journal=true` will cause fluentd to use the systemd journal for
the logging source.  This requires docker 1.10 or later, and docker must be configured to
use `--log-driver=journald`.  Fluentd will first look for `/var/log/journal`,
and if that is not available, will use `/run/log/journal` as the journal
source.
* `journal-source`:  You can override the source that fluentd uses for the
 journal.  For example, if you want fluentd to always use the transient
 in-memory journal, set `journal-source=/run/log/journal`.
* `journal-read-from-head=[false|true]`: If this setting is `false`,
fluentd will start reading from the end of the journal - no historical logs.
If this setting is `true`, fluentd will start reading logs from the beginning.
*NOTE*: It may require several minutes, or
hours, depending on the size of your journal, before any new log entries are
available in Elasticsearch, when using `journal-read-from-head=true`.
*NOTE*: DO NOT USE `journal-read-from-head=true` IF YOU HAVE PREVIOUSLY USED
`journal-read-from-head=false` - you will fill up your Elasticsearch with
duplicate records.

An invocation supplying the most important parameters might be:

    $ oc create configmap logging-deployer \
       --from-literal kibana-hostname=kibana.example.com \
       --from-literal public-master-url=https://localhost:8443 \
       --from-literal es-cluster-size=3

It is also relatively easy to edit `ConfigMap` YAML after creating it:

    $ oc edit configmap logging-deployer

### Create Deployer Secret

Security parameters for the logging infrastructure
deployment can be supplied to the deployer in the form of a
Most other parameters can be supplied in the form of a ConfigMap.
Actually, the following parameters can all be supplied either way; but
files used for security purposes are typically supplied in a secret.

All contents of the secret and configmap are optional (they will be
generated/defaulted if not supplied). The following files may be supplied
in the `logging-deployer` secret:

* `kibana.crt` - A browser-facing certificate for the Kibana route. If not supplied, the route is secured with the default router cert.
* `kibana.key` - A key to be used with the Kibana certificate.
* `kibana-ops.crt` - A browser-facing certificate for the Ops Kibana route. If not supplied, the route is secured with the default router cert.
* `kibana-ops.key` - A key to be used with the Ops Kibana certificate.
* `kibana-internal.crt` - An internal certificate for the Kibana server.
* `kibana-internal.key` - A key to be used with the internal Kibana certificate.
* `server-tls.json` - JSON TLS options to override the internal Kibana TLS defaults; refer to
  [NodeJS docs](https://nodejs.org/api/tls.html#tls_tls_connect_options_callback) for
  available options and the [default options](conf/server-tls.json) for an example.
* `ca.crt` - A certificate for a CA that will be used to sign and validate any
  certificates generated by the deployer.
* `ca.key` - A matching CA key.

An invocation supplying a properly signed Kibana cert might be:

    $ oc create secret generic logging-deployer \
       --from-file kibana.crt=/path/to/cert \
       --from-file kibana.key=/path/to/key

### Choose Template Parameters

When running the deployer in the next step, there are a few parameters
that are specified directly if needed:

* `IMAGE_PREFIX`: Specify the prefix for logging component images; e.g. for "docker.io/openshift/origin-logging-deployer:v1.2.0", set prefix "docker.io/openshift/origin-"
* `IMAGE_VERSION`: Specify version for logging component images; e.g. for "docker.io/openshift/origin-logging-deployer:v1.2.0", set version "v1.2.0"
* `MODE`: Mode to run the deployer in; one of `install`, `uninstall`, `reinstall`, `upgrade`, `migrate`, `start`, `stop`. `migrate` refers to the ES UUID data migration that is required for upgrading from version 1.1. `stop` and `start` can be used to safely pause the cluster for maintenance.

## Run the Deployer

You run the deployer by instantiating a template. Here is an example with
some parameters (just for demonstration purposes -- none are required):

    $ oc new-app logging-deployer-template \
               -p IMAGE_VERSION=v1.2.0 \
               -p MODE=install

This creates a deployer pod and prints its name. As this is running in
`install` mode (which the default), it will create a new deployment of
the EFK stack. Wait until the pod is running; this can take up to a few
minutes to retrieve the deployer image from its registry. You can watch
it with:

    $ oc get pod/<pod-name> -w

If it seems to be taking too long, you can retrieve more details about
the pod and any associated events with:

    $ oc describe pod/<pod-name>

When it runs, check the logs of the resulting pod (`oc logs -f <pod name>`)
for some instructions to follow after deployment. More details
are given below.

## Adjusting the Deployment

Read on to learn about Elasticsearch parameters, how to have Fluentd
deployed, what the Ops cluster is for and explain the contents of the secrets the
deployer creates and how to change them.

### Ops cluster

If you set `enable-ops-cluster` to `true` for the deployer, fluentd
expects to split logs between the main ElasticSearch cluster and another
cluster reserved for operations logs (which are defined as node system
logs and the projects `default`, `openshift`, and `openshift-infra`). Thus
a separate Elasticsearch cluster, a separate Kibana, and a separate
Curator are deployed to index, access, and manage operations logs. These
deployments are set apart with the `-ops` included in their names. Keep
these separate deployments in mind while reading the following.

### ElasticSearch

The deployer creates the number of ElasticSearch instances specified by
`es-cluster-size`. The nature of ElasticSearch and current Kubernetes
limitations require that we use a different scaling mechanism than the
standard Kubernetes scaling.

Scaling a standard deployment (a Kubernetes ReplicationController)
to multiple pods currently mounts the same volumes on all pods in the
deployment. However, multiple ElasticSearch instances in a cluster
cannot share storage; each pod requires its own storage. Work is under
way to enable specifying multiple volumes to be allocated individually
to instances in a deployment, but for now the deployer creates multiple
deployments in order to scale ElasticSearch to multiple instances. You
can view the deployments with:

    $ oc get dc --selector logging-infra=elasticsearch

These deployments all have different names but will cluster with each other
via `service/logging-es-cluster`.

It is possible to scale your cluster up after creation by adding more
deployments from a template; however, scaling up (or down) requires
the correct procedure and an awareness of clustering parameters (to be
described in a separate section). It is best if you can indicate the
desired scale at first deployment.

Refer to [Elastic's
documentation](https://www.elastic.co/guide/en/elasticsearch/guide/current/hardware.html#_disks)
for considerations involved in choosing storage and network location
as directed below.

#### Storage

By default, the deployer creates an ephemeral deployment in which all
of a pod's data will be lost any time it is restarted. For production
use you should specify a persistent storage volume for each deployment
of ElasticSearch. The deployer parameters with `-pvc-` in the name should
be used for this. You can either use a pre-existing set of PVCs (specify
a common prefix for their names and append numbers starting at 1, for
example with default prefix `logging-es-` supply PVCs `logging-es-1`,
`logging-es-2`, etc.), or the deployer can create them with a request
for a specified size. This is the recommended method of supplying
persistent storage.

You may instead choose to add volumes manually to deployments with the
`oc volume` command. For example, to use a local directory on the host
(which is actually recommended by Elastic in order to take advantage of
local disk performance):

    $ oc volume dc/logging-es-rca2m9u8 \
              --add --overwrite --name=elasticsearch-storage \
              --type=hostPath --path=/path/to/storage

Note: In order to allow the pods to mount host volumes, you would usually
need to add the `aggregated-logging-elasticsearch` service account to
the `hostmount-anyuid` SCC similar to Fluentd as shown above. Use node
selectors and node labels carefully to ensure that pods land on nodes
with the storage you intend.

See `oc volume -h` for further options. E.g. if you have a specific NFS volume
you would like to use, you can set it with:

    $ oc volume dc/logging-es-rca2m9u8 \
              --add --overwrite --name=elasticsearch-storage \
              --source='{"nfs": {"server": "nfs.server.example.com", "path": "/exported/path"}}'

#### Node selector

ElasticSearch can be very resource-heavy, particularly in RAM, depending
on the volume of logs your cluster generates. Per Elastic's guidance,
all members of the cluster should have low latency network connections
to each other.  You will likely want to direct the instances to dedicated
nodes, or a dedicated region in your cluster. You can do this by supplying
a node selector in each deployment.

The deployer has options to specify a nodeSelector label for Elasticsearch, Kibana
and Curator. If you have already deployed the EFK stack or would like to customize
your nodeSelector labels per deployment, see below.

There is no helpful command for adding a node selector (yet). You will
need to `oc edit` each DeploymentConfig and add or modify the `nodeSelector`
element to specify the label corresponding to your desired nodes, e.g.:

    apiVersion: v1
    kind: DeploymentConfig
    spec:
      template:
        spec:
          nodeSelector:
            nodelabel: logging-es-node-1

Alternatively, you can use `oc patch` to do this as well:
```
oc patch dc/logging-es-{unique name} -p '{"spec":{"template":{"spec":{"nodeSelector":{"nodelabel":"logging-es-node-1"}}}}}'
```

Recall that the default scheduler algorithm will spread pods to different
nodes (in the same region, if regions are defined). However this can
have unexpected consequences in several scenarios and you will most
likely want to label and specify designated nodes for ElasticSearch.

#### Cluster parameters

There are some administrative settings that can be supplied (ref. [Elastic documentation](https://www.elastic.co/guide/en/elasticsearch/guide/current/_important_configuration_changes.html)).

* `minimum_master_nodes` - the quorum required to elect a new master. Should be more than half the intended cluster size.
* `recover_after_nodes` - when restarting the cluster, require this many nodes to be present before starting recovery.
* `expected_nodes` and `recover_after_time` - when restarting the cluster, wait for number of nodes to be present or time to expire before starting recovery.

These are, respectively, the `NODE_QUORUM`, `RECOVER_AFTER_NODES`,
`RECOVER_EXPECTED_NODES`, and `RECOVER_AFTER_TIME` parameters in the
ES deployments and the ES template. The deployer also enables specifying
these parameters. However, usually the defaults
should be sufficient, unless you need to scale ES after deployment.

### Fluentd

Fluentd is deployed as a DaemonSet that deploys replicas according
to a node label selector (which you can choose; the default is
`logging-infra-fluentd`). Once you have ElasticSearch running as
desired, label the nodes to deploy Fluentd to in order to feed
logs into ES. The example below would label a node named
'ip-172-18-2-170.ec2.internal' using the default Fluentd node selector.

    $ oc label node/ip-172-18-2-170.ec2.internal logging-infra-fluentd=true

Alternatively, you can label all nodes with the following:

    $ oc label node --all logging-infra-fluentd=true

Note: Labeling nodes requires cluster-admin capability.

#### Throttling logs in Fluentd

For projects that are especially verbose, an administrator can throttle
down the rate at which the logs are read in by Fluentd before being
processed. Note: this means that aggregated logs for the configured
projects could fall behind and even be lost if the pod were deleted
before Fluentd caught up.

*NOTE* Throttling does not work when using the systemd journal as the log
source.  The throttling implementation depends on being able to throttle the
reading of the individual log files for each project.  When reading from the
journal, there is only a single log source, no log files, so no file-based
throttling is available, and there isn't a method of restricting which log
entries are read into the fluentd process _before_ they get into the fluentd
process address space.

To tell Fluentd which projects it should be restricting you will need
to edit the throttle configuration in its configmap after deployment:

    $ oc edit configmap/logging-fluentd

The format of the throttle-config.yaml key is a yaml file that contains
project names and the desired rate at which logs are read in on each
node. The default is 1000 lines at a time. For example:

```
logging:
  read_lines_limit: 500

test-project:
  read_lines_limit: 10

.operations:
  read_lines_limit: 100
```

Directly editing is the simplest method, but you may prefer maintaining
a large file of throttle settings and just reusing the file. You can
export and recreate the configmap as follows:

```
$ tmpdir=$(mktemp -d /tmp/fluentd-configmap.XXXXXXXX)
$ for key in $(oc get configmap/logging-fluentd \
               --template '{{range $key, $val := .data}}{{$key}} {{end}}')
    do oc get configmap/logging-fluentd \
               --template "{{index .data \"$key\"}}" > $tmpdir/$key
  done
[ ... modify file(s) as needed ... ]
$ oc create configmap logging-fluentd --from-file=$tmpdir -o yaml | oc replace -f -
```

Once you have modified the configmap as needed, the fluentd pods must be
restarted in order to recognize the change. The simplest way to do this is
to delete them all:

    $ oc delete pods -l provider=openshift,component=fluentd

#### Have Fluentd send logs to another Elasticsearch

You can configure Fluentd to send a copy of each log message to both the
Elasticsearch instance included with OpenShift aggregated logging, _and_ to an
external Elasticsearch instance.  For example, if you already have an
Elasticsearch instance set up for auditing purposes, or data warehousing, you
can send a copy of each log message to that Elasticsearch, in addition to the
the Elasticsearch hosted with OpenShift aggregated logging.

If the environment variable `ES_COPY` is `"true"`, Fluentd will send a copy of
the logs to another Elasticsearch. The settings for the copy are just like the
current `ES_HOST`, etc. and `OPS_HOST`, etc. settings, except that they add
`_COPY`: `ES_COPY_HOST`, `OPS_COPY_HOST`, etc.  There are some additional
parameters added:
* `ES_COPY_SCHEME`, `OPS_COPY_SCHEME` - can use either http or https - defaults
  to https
* `ES_COPY_USERNAME`, `OPS_COPY_USERNAME` - user name to use to authenticate to
  elasticsearch using username/password auth
* `ES_COPY_PASSWORD`, `OPS_COPY_PASSWORD` - password to use to authenticate to
  elasticsearch using username/password auth

To set the parameters:

    oc edit -n logging template logging-fluentd-template
    # add/edit ES_COPY to have the value "true" - with the quotes
    # add or edit the COPY parameters listed above
    # automated:
    #   oc get -n logging template logging-fluentd-template -o yaml > file
    #   edit the file with sed/perl/whatever
    #   oc replace -n logging -f file
    oc delete daemonset logging-fluentd
    # wait for fluentd to stop
    oc process -n logging logging-fluentd-template | \
      oc create -n logging -f -
    # this creates the daemonset and starts fluentd with the new params

#### Have Fluentd use the systemd journal as the log source

By default, fluentd will read from `/var/log/messages*` and
`/var/log/containers/*.log` for system logs and container logs, respectively.
You can use the systemd journal instead as the log source.  There are three
deployer configuration parameters set in the deployer configmap: `use-journal`,
`journal-source`, and `journal-read-from-head`.
* `use-journal=[false|true]` - default is empty.  This tells the
deployer/fluentd to see which log driver docker is using - if docker is using
`--log-driver=journald`, this means `use-journal=true`, and fluentd will read
from the systemd journal, otherwise, it will assume docker is using the
`json-file` log driver and read from the `/var/log` file sources. Using the
systemd journal requires docker 1.10 or later, and docker must be configured to
use `--log-driver=journald`.  If using the systemd journal, Fluentd will first
look for `/var/log/journal`, and if that is not available, will use
`/run/log/journal` as the journal source.
* `journal-source=/path/to/journal` - default is empty.  This is the location
of the journal to use.  For example, if you want fluentd to always read logs
from the transient in-memory journal, set `journal-source=/run/log/journal`.
* `journal-read-from-head=[false|true]` - If this setting is `false`, fluentd
will start reading from the end of the journal - no historical logs.  If this
setting is `true`, fluentd will start reading logs from the beginning.
*NOTE*: It may require several minutes, or hours, depending on the size of your
journal, before any new log entries are available in Elasticsearch, when using
`journal-read-from-head=true`.
*NOTE*: DO NOT USE `journal-read-from-head=true` IF YOU HAVE PREVIOUSLY USED
`journal-read-from-head=false` - you will fill up your Elasticsearch with
duplicate records.

### Kibana

You may scale the Kibana deployment normally for redundancy:

    $ oc scale dc/logging-kibana --replicas=2
    $ oc scale rc/logging-kibana-1 --replicas=2

You should be able to visit the `KIBANA_HOSTNAME` specified in the
initial deployment to visit the UI (assuming DNS points correctly for
this domain). You will get a certificate warning if you did not provide
a properly signed certificate in the deployer secret. You should be able
to login with the same users that can login to the web console and have
index patterns defined for projects the user has access to.

### Curator

One curator replica is recommended for each Elasticsearch cluster.

Curator allows the admin to remove old indices from Elasticsearch on a
per-project basis. It reads its configuration from a mounted yaml file
that is structured like this:

    $PROJECT_NAME:
      $ACTION:
        $UNIT: $VALUE

    $PROJECT_NAME:
      $ACTION:
        $UNIT: $VALUE
     ...

* $PROJECT\_NAME - the actual name of a project - "myapp-devel"
** For operations logs, use the name `.operations` as the project name
* $ACTION - the action to take - currently only "delete"
* $UNIT - one of "days", "weeks", or "months"
* $VALUE - an integer for the number of units
* `.defaults` - use `.defaults` as the $PROJECT\_NAME to set the defaults for
projects that are not specified
** runhour: NUMBER - hour of the day in 24 hour format at which to run the
curator jobs
** runminute: NUMBER - minute of the hour at which to run the curator jobs

For example, using:

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
        days: 30
      runhour: 0
      runminute: 0
    ...

Every day, curator runs to delete indices in the myapp-dev
project older than 1 day, and indices in the myapp-qe project older than 1
week.  All other projects have their indices deleted after they are 30
days old.  The curator jobs run at midnight every day.

*WARNING*: Using `months` as the unit

When you use month-based trimming, curator starts counting at the _first_ day of
the current month, not the _current_ day of the current month.  For example, if
today is April 15, and you want to delete indices that are 2 months older than
today (`delete: months: 2`), curator doesn't delete indices that are dated
older than February 15, it deletes indices older than _February 1_.  That is,
it goes back to the first day of the current month, _then_ goes back two whole
months from that date.
If you want to be exact with curator, it is best to use `days` e.g. `delete: days: 30`
[Curator issue](https://github.com/elastic/curator/issues/569)

To create the curator configuration, you can just edit the current
configuration in the deployed configmap:

    $ oc edit configmap/logging-curator

Since it can be tricky to get YAML indentation correct in this context, you may
prefer to create a yaml file with your configuration settings using your favorite editor.
Next create a secret from your created yaml file:

    $ oc create secret generic index-management \
         --from-file config.yaml=</path/to/your/yaml/file>

Then overwrite the configuration with your created secret as a volume in your Curator DC:

    $ oc set volume dc/logging-curator --overwrite --name=config \
             --type=secret --secret-name=index-management
    $ oc deploy --latest logging-curator

### About the Deployer generated secrets

Part of the installation process that is done by the logging deployer is to generate
certificates and keys and make them available to the logging components by means
of secrets.

The secrets that the components make use of are:

    logging-curator
    logging-curator-ops
    logging-elasticsearch
    logging-fluentd
    logging-kibana
    logging-kibana-proxy

#### logging-curator, logging-kibana, logging-fluentd

These three components all have a `ca`, `key` and `cert` entries.  These are what
are used for mutual TLS communication with Elasticsearch.
  1. `ca` contains the certificate to validate the Elasticsearch server certificate.
  2. `key` is the generated key specific to that component.
  3. `cert` is the client certificate created using `key`.

#### logging-kibana-proxy

The Kibana proxy container is used to serve requests from clients outside of the
cluster.  It contains `oauth-secret`, `server-cert`, `server-key`, `server-tls.json`
and `session-secret`.
  1. `oauth-secret` is used to communicate with the oauthclient created as part of
the aggregated logging installation to redirect requests for authentication with
the OpenShift console.
  2. `server-cert` is the browser-facing certificate served up by the auth proxy
  3. `server-key` is the browser-facing key served up by the auth proxy
  4. `server-tls.json` is the proxy TLS configuration file
  5. `session-secret` contains the generated proxy session that is used to secure
the user's cookie containing their auth token once obtained.

#### logging-elasticsearch

Elasticsearch is the central piece for aggregated logging.  It ensures that communication
between itself and the other components is secure as well as securing communication
between its other Elasticsearch cluster members.  It contains `admin-ca`, `admin-cert`,
`admin-key`, `key`, `searchguard.key` and `truststore`.
  1. `admin-ca` contains the ca to be used when doing ES operations as the admin user.
  2. `admin-cert` is the client certificate for the admin user corresponding to `admin-key`
  3. `admin-key` contains the generated key for the ES admin user.
  4. `key` contains the Elasticsearch server key and certificate used by Searchguard for mutual TLS
  5. `searchguard.key` contains the generated key used for communication with other
Elasticsearch cluster members.
  6. `truststore` contains the CA that validates client certificates

#### Changing secret contents

Disclaimer: Changing the contents of secrets may result in a non-working aggregated
logging installation if not done correctly. As with any other changes to your
aggregated logging cluster, you should stop your cluster prior to making any
changes to secrets to minimize the loss of log records.

The contents of secrets are base64 encoded, so when patching we need to ensure that
the value we are replacing with is encoded. If we wanted to change the `key` value
in `secret/logging-curator` and replace it with the contents of the file `new_key.key`
we would use (assuming the bash shell):

    $ oc patch secret/logging-curator -p='{"data":{"key": "'$(base64 -w 0 < new_key.key)'"}}'

## Upgrading your EFK stack

If you need to upgrade your EFK stack with new images and new features, you can
run the Deployer in `upgrade` mode.

Before you run the Deployer you should recreate your `logging-deployer-template`
and `logging-deployer-account-template` templates to ensure you pick up any changes
that may have been made to them since your last installation. First, you must delete
the templates.

    $ oc delete template logging-deployer-account-template logging-deployer-template

You can follow the steps [here](https://github.com/openshift/origin-aggregated-logging/tree/master/deployer#create-missing-templates)
to recreate your Deployer templates.  Then follow the steps [here](https://github.com/openshift/origin-aggregated-logging/tree/master/deployer#create-supporting-serviceaccount-and-permissions)
to ensure your service account roles are up to date.

To run the Deployer to upgrade your EFK stack, run the deployer with the `MODE=upgrade` parameter.

    $ oc new-app logging-deployer-template -p MODE=upgrade

Upgrade mode will take care of the following for you:
  * Scale down your EFK deployment in a manner that will have minimal disruption
  to your log data.
  * Pull down the latest EFK image tags and patch your templates/DCs
  * Perform any infrastructure changes in a non-destructive manner -- if you don't
  yet have Curator, the upgrade won't delete your old ES instances
  * Scale your deployment back up as best as it can -- if you are moving from
  Fluentd being deployed with a DC to a Daemonset, the deployer can't label your
  nodes for you but it'll inform you how to!
  * If you did not previously have an admin-cert the upgrade will also perform
  the necessary uuid index migration for you.

#### Note
  If you have not previously done a uuid migration after a manual upgrade, you will
  need to perform that with `MODE=migrate` while your Elasticsearch instances
  are running.

  This only impacts non-operations logs, operations logs will appear the
  same as in previous versions. There should be minimal performance impact to ES
  while running this and it will not perform an install.

## Stop and Start

If you wish to shut down in an orderly fashion, for instance prior to a system upgrade,
there are stop and start a deployer modes:

    $ oc new-app logging-deployer-template -p MODE=stop
    $ oc new-app logging-deployer-template -p MODE=start

In each case, the deployer must `Complete` state before the action can
be considered complete.

## Uninstall and Reinstall

If you wish to remove everything generated or instantiated without having
to destroy the project, there is a deployer mode to do so cleanly:

    $ oc new-app logging-deployer-template -p MODE=uninstall

You can also typically do so manually:

    $ oc delete all,sa,oauthclient,daemonset,configmap --selector logging-infra=support
    $ oc delete secret logging-fluentd logging-elasticsearch \
                       logging-elasticsearch logging-kibana \
                       logging-kibana-proxy

Note that PersistentVolumeClaims are preserved, not deleted.

There is also a reinstall mode:

    $ oc new-app logging-deployer-template -p MODE=reinstall

This first removes the deployment and then recreates it according to
current parameters. Note that again, PersistentVolumeClaims are preserved,
and may be reused by the new deployment. This is a useful way to make
the deployment match changed parameters without losing data.

# Using Kibana

The subject of using Kibana in general is covered in that [project's
documentation](https://www.elastic.co/guide/en/kibana/4.1/discover.html).
Here is some information specific to the aggregated logging deployment.

1. Login is performed via OAuth2, as with the web console. The default certificate
authentication used for the admin user isn't available, but you can create
other users and make them cluster admins.
2. Kibana and ElasticSearch have been customized to display logs only
to users that have access to the projects the logs came from. So if you login
and have no access to anything, be sure your user has access to at least one
project. Cluster admin users should have access to all project logs as
well as host logs.
3. To do anything with ElasticSearch and Kibana, Kibana has to have
defined some index patterns that match indices being recorded in
ElasticSearch. This should already be done for you, but you should be
aware how these work in case you want to customize anything. When logs
from applications in a project are recorded, they are indexed by project
name and date in the format `name.YYYY-MM-DD`. For matching a project's
logs for all dates, an index pattern will be defined in Kibana for each
project which looks like `name.*`.
4. When first visiting Kibana, the first page directs you to create
an index pattern.  In general this should not be necessary and you can
just click the "Discover" tab and choose a project index pattern to see
logs. If there are no logs yet for a project, you won't get any results;
keep in mind also that the default time interval for retrieving logs is
15 minutes and you will need to adjust it to find logs older than that.
5. Unfortunately there is no way to stream logs as they are created at
this time.

# Adjusting ElasticSearch After Deployment

If you need to change the ElasticSearch cluster size after deployment,
DO NOT just scale existing deployments up or down. ElasticSearch cannot
scale by ordinary Kubernetes mechanisms, as explained above. Each instance
requires its own storage, and thus under current capabilities, its own
deployment. The deployer defined a template `logging-es-template` which
can be used to create new ElasticSearch deployments.

Adjusting the scale of the ElasticSearch cluster
typically requires adjusting cluster parameters that
vary by cluster size. [Elastic documentation discusses these
issues](https://www.elastic.co/guide/en/elasticsearch/guide/current/_important_configuration_changes.html)
and the corresponding parameters are coded as environment variables
in the existing deployments and parameters in the deployment template
(mentioned in the [Settings](#settings) section).  The deployer chooses sensible
defaults based on cluster size. These should be adjusted for both new
and existing deployments when changing the cluster size.

Changing cluster parameters (or any parameters/secrets, really) requires
re-deploying the instances. In order to minimize resynchronization
between the instances as they are restarted, we advise halting traffic to
ElasticSearch and then taking down the entire cluster for maintenance. No
logs will be lost; Fluentd simply blocks until the cluster returns.

Halting traffic to ElasticSearch requires scaling down Kibana and removing node labels for Fluentd:

    $ oc label node --all logging-infra-
    $ oc scale rc/logging-kibana-1 --replicas=0

Next scale all of the ElasticSearch deployments to 0 similarly.

    $ oc get rc --selector logging-infra=elasticsearch
    $ oc scale rc/logging-es-... --replicas=0

Now edit the existing DeploymentConfigs and modify the variables as needed:

    $ oc get dc --selector logging-infra=elasticsearch
    $ oc edit dc logging-es-...

You can adjust parameters in the template (`oc edit template logging-es-template`) and reuse it to add more instances:

    $ oc process logging-es-template | oc create -f -

Keep in mind that these are deployed immediately and will likely need
storage and node selectors defined. You may want to scale them down to
0 while operating on them.

Once all the deployments are properly configured, deploy them all at
about the same time.

    $ oc get dc --selector logging-infra=elasticsearch
    $ oc deploy --latest logging-es-...

The cluster parameters determine how cluster formation and recovery
proceeds, but the default is that the cluster will wait up to five minutes
for all instances to start up and join the cluster. After the cluster
is formed, new instances will begin replicating data from the existing
instances, which can take a long time and generate a lot of network
traffic and disk activity, but the cluster is operational immediately and
Kibana can be scaled back to its normal operating levels and nodes can be re-labeled
for Fluentd.

    $ oc label node --all logging-infra-fluentd=true
    $ oc scale rc/logging-kibana-1 --replicas=2


# Checking EFK Health

Determining the health of an EFK deployment and if it is running can be assessed
as follows.

### Fluentd

Check Fluentd logs for the message that it has read in its config file:
```
2016-02-19 20:40:44 +0000 [info]: reading config file path="/etc/fluent/fluent.conf"
```

After that, you can verify that fluentd has been able to start reading in log files
by checking the contents of `/var/log/node.log.pos` and `/var/log/es-containers.log.pos`.
node.log.pos will keep track of the placement in syslog log files and es-containers.log.pos
will keep track of the placement in the docker log files (/var/log/containers).  Or, if you
are using the systemd journal as the log source, look in `/var/log/journal.pos`.

### Elasticsearch

Elasticsearch will have more logs upon start up than Fluentd and it will give you
more information such as how many indices it recovered upon starting up.
```
[2016-02-19 20:40:42,983][INFO ][node                     ] [Volcana] version[1.5.2], pid[7], build[62ff986/2015-04-27T09:21:06Z]
[2016-02-19 20:40:42,983][INFO ][node                     ] [Volcana] initializing ...
[2016-02-19 20:40:43,546][INFO ][plugins                  ] [Volcana] loaded [searchguard, openshift-elasticsearch-plugin, cloud-kubernetes], sites []
[2016-02-19 20:40:46,749][INFO ][node                     ] [Volcana] initialized
[2016-02-19 20:40:46,767][INFO ][node                     ] [Volcana] starting ...
[2016-02-19 20:40:46,834][INFO ][transport                ] [Volcana] bound_address {inet[/0:0:0:0:0:0:0:0:9300]}, publish_address {inet[/172.17.0.1:9300]}
[2016-02-19 20:40:46,843][INFO ][discovery                ] [Volcana] logging-es/WJSOLSgsRuSe183-LE0WwA
SLF4J: Class path contains multiple SLF4J bindings.
SLF4J: Found binding in [jar:file:/usr/share/elasticsearch/plugins/openshift-elasticsearch-plugin/slf4j-log4j12-1.7.7.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: Found binding in [jar:file:/usr/share/elasticsearch/plugins/cloud-kubernetes/slf4j-log4j12-1.7.7.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: See http://www.slf4j.org/codes.html#multiple_bindings for an explanation.
SLF4J: Actual binding is of type [org.slf4j.impl.Log4jLoggerFactory]
[2016-02-19 20:40:49,980][INFO ][cluster.service          ] [Volcana] new_master [Volcana][WJSOLSgsRuSe183-LE0WwA][logging-es-4sbwcpvw-1-d5j4y][inet[/172.17.0.1:9300]], reason: zen-disco-join (elected_as_master)
[2016-02-19 20:40:50,005][INFO ][http                     ] [Volcana] bound_address {inet[/0:0:0:0:0:0:0:0:9200]}, publish_address {inet[/172.17.0.1:9200]}
[2016-02-19 20:40:50,005][INFO ][node                     ] [Volcana] started
[2016-02-19 20:40:50,384][INFO ][gateway                  ] [Volcana] recovered [0] indices into cluster_state
```
At this point, you know that ES is currently up and running.

If you see a stack trace like the following from `com.floragunn.searchguard.service.SearchGuardConfigService` you can ignore it.  This is due
to the Search Guard plugin not gracefully handling the ES service not being up and ready at the time Search Guard is querying for its configurations.
While you can ignore stack traces from Search Guard it is important to still review them to determine why may ES may not have started up,
especially if the Search Guard stack trace is repeated multiple times:
```
[2016-01-19 19:30:48,980][ERROR][com.floragunn.searchguard.service.SearchGuardConfigService] [Topspin] Try to refresh security configuration but it failed due to org.elasticsearch.action.NoShardAvailableActionException: [.searchguard.logging-es-0ydecq1l-2-o0z5s][4] null
org.elasticsearch.action.NoShardAvailableActionException: [.searchguard.logging-es-0ydecq1l-2-o0z5s][4] null
	at org.elasticsearch.action.support.single.shard.TransportShardSingleOperationAction$AsyncSingleAction.perform(TransportShardSingleOperationAction.java:175)

	...

	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:617)
	at java.lang.Thread.run(Thread.java:745)
```

Since Fluentd and Kibana both talk to Elasticsearch, the Elasticsearch logs are a good place to go for
verifying that connections are active.

You can see what indices have been created by Fluentd pushing logs to Elasticsearch:
```
[2016-02-19 21:01:53,867][INFO ][cluster.metadata         ] [M-Twins] [logging.2016.02.19] creating index, cause [auto(bulk api)], templates [], shards [5]/[1], mappings [fluentd]
[2016-02-19 21:02:20,593][INFO ][cluster.metadata         ] [M-Twins] [.operations.2016.02.19] creating index, cause [auto(bulk api)], templates [], shards [5]/[1], mappings [fluentd]
```

After a user first signs into Kibana their Kibana profile will be created and saved in the index `.kibana.{user-name sha hash}`.

### Kibana

The Kibana pod contains two containers.  One container is `kibana-proxy`, and the other is `kibana` itself.

Kibana-proxy will print out this line to state that it has started up:
```
Starting up the proxy with auth mode "oauth2" and proxy transform "user_header,token_header".
```

Kibana will print out lines until it has successfully connected to its configured Elasticsearch. It is important to note that Kibana will not be
available until it has connected to ES.
```
{"name":"Kibana","hostname":"logging-kibana-3-1menz","pid":8,"level":30,"msg":"No existing kibana index found","time":"2016-02-19T21:14:02.723Z","v":0}
{"name":"Kibana","hostname":"logging-kibana-3-1menz","pid":8,"level":30,"msg":"Listening on 0.0.0.0:5601","time":"2016-02-19T21:14:02.743Z","v":0}
```

Currently Kibana is very verbose in its logs and will actually print every http request/response made.  As of 4.2 there is a means to set
log levels, however EFK is currently using 4.1.2 due to compatibility with the version of ES used (1.5.2).


# Troubleshooting

There are a number of common problems with logging deployment that have simple
explanations but do not present useful errors for troubleshooting.

### Looping login on Kibana

The experience here is that when you visit Kibana, it redirects you to
login. Then when you login successfully, you are redirected back to Kibana,
which immediately redirects back to login again.

The typical reason for this is that the OAuth2 proxy in front of Kibana
is supposed to share a secret with the master's OAuth2 server, in order
to identify it as a valid client. This problem likely indicates that
the secrets do not match (unfortunately nothing reports this problem
in a way that can be exposed). This can happen when you deploy logging
more than once (perhaps to fix the initial deployment) and the `secret`
used by Kibana is replaced while the master `oauthclient` entry to match
it is not.

In this case, you should be able to do the following:

    $ oc delete oauthclient/kibana-proxy
    $ oc process logging-support-template | oc create -f -

This will replace the oauthclient (and then complain about the other
things it tries to create that are already there - this is normal). Then
your next successful login should not loop.

### "error":"invalid\_request" on login

When you visit Kibana directly and it redirects you to login, you instead
receive an error in the browser like the following:

     {"error":"invalid_request","error_description":"The request is missing a required parameter,
      includes an invalid parameter value, includes a parameter more than once, or is otherwise malformed."}

The reason for this is again a mismatch between the OAuth2 client and server.
The return address for the client has to be in a whitelist for the server to
securely redirect back after logging in; if there is a mismatch, then this
cryptic error message is shown.

As above, this may be caused by an `oauthclient` entry lingering from a
previous deployment, in which case you can replace it:

    $ oc delete oauthclient/kibana-proxy
    $ oc process logging-support-template | oc create -f -

This will replace the `oauthclient` (and then complain about the other
things it tries to create that are already there - this is normal).
Return to the Kibana URL and try again.

If the problem persists, then you may be accessing Kibana at
a URL that the `oauthclient` does not list. This can happen when, for
example, you are trying out logging on a vagrant-driven VirtualBox
deployment of OpenShift and accessing the URL at forwarded port 1443
instead of the standard 443 HTTPS port. Whatever the reason, you can
adjust the server whitelist by editing its `oauthclient`:

    $ oc edit oauthclient/kibana-proxy

This brings up a YAML representation in your editor, and you can edit
the redirect URIs accepted to include the address you are actually using.
After you save and exit, this should resolve the error.

### Deployment fails, RCs scaled to 0

When a deployment is performed, if it does not successfully bring up an
instance before a ten-minute timeout, it will be considered failed and
scaled down to zero instances. `oc get pods` will show a deployer pod
with a non-zero exit code, and no deployed pods, e.g.:

    NAME                           READY     STATUS             RESTARTS   AGE
    logging-es-2e7ut0iq-1-deploy   1/1       ExitCode:255       0          1m

(In this example, the deployer pod name for an ElasticSearch deployment is shown;
this is from ReplicationController `logging-es-2e7ut0iq-1` which is a deployment
of DeploymentConfig `logging-es-2e7ut0iq`.)

Deployment failure can happen for a number of transitory reasons, such as
the image pull taking too long, or nodes being unresponsive. Examine the
deployer pod logs for possible reasons; but often you can simply redeploy:

    $ oc deploy --latest logging-es-2e7ut0iq

Or you may be able to scale up the existing deployment:

    $ oc scale --replicas=1 logging-es-2e7ut0iq-1

If the problem persists, you can examine pods, events, and systemd unit
logs to determine the source of the problem.

### Image pull fails

If you specify an IMAGE\_PREFIX that results in images being defined that don't exist,
you will receive a corresponding error message, typically after creating the deployer.

    NAME                     READY     STATUS                                                                                       RESTARTS   AGE
    logging-deployer-1ub9k   0/1       Error: image registry.access.redhat.com:5000/openshift3logging-deployment:latest not found   0          1m

In this example, for the intended image name
`registry.access.redhat.com:5000/openshift3/logging-deployment:latest`
the `IMAGE\_PREFIX` needed a trailing `/`:

    $ oc process logging-deployer-template \
               -v IMAGE_PREFIX=registry.access.redhat.com:5000/openshift3/,...

You can just re-create the deployer with the proper parameters to proceed.

### Can't resolve kubernetes.default.svc.cluster.local

This internal alias for the master should be resolvable by the included
DNS server on the master. Depending on your platform, you should be able
to run the `dig` command (perhaps in a container) against the master to
check whether this is the case:

    master$ dig kubernetes.default.svc.cluster.local @localhost
    [...]
    ;; QUESTION SECTION:
    ;kubernetes.default.svc.cluster.local. IN A

    ;; ANSWER SECTION:
    kubernetes.default.svc.cluster.local. 30 IN A   172.30.0.1

Older versions of OpenShift did not automatically define this internal
alias for the master. You may need to upgrade your cluster in order to
use aggregated logging. If your cluster is up to date, there may be
a problem with your pods reaching the SkyDNS resolver at the master,
or it could have been blocked from running. You should resolve this
problem before deploying again.

### Can't connect to the master or services

If DNS resolution does not return at all or the address cannot be
connected to from within a pod (e.g. the deployer pod), this generally
indicates a system firewall/network problem and should be debugged
as such.

### Kibana access shows 503 error

If everything is deployed but visiting Kibana results in a proxy
error, then one of the following things is likely to be the issue.

First, Kibana might not actually have any pods that are recognized
as running. If ElasticSearch is slow in starting up, Kibana may
error out trying to reach it, and won't be considered alive. You can
check whether the relevant service has any endpoints:

    $ oc describe service logging-kibana
    Name:                   logging-kibana
    [...]
    Endpoints:              <none>

If any Kibana pods are live, endpoints should be listed. If they are
not, check the state of the Kibana pod(s) and deployment.

Second, the named route for accessing the Kibana service may be masked.
This tends to happen if you do a trial deployment in one project and
then try to deploy in a different project without completely removing the first one.
When multiple routes are declared for the same destination, the default router will route to
the first created. You can check if the route in question is defined in multiple places with:

    $ oc get route  --all-namespaces --selector logging-infra=support
    NAMESPACE   NAME         HOST/PORT                 PATH      SERVICE
    logging     kibana       kibana.example.com                  logging-kibana
    logging     kibana-ops   kibana-ops.example.com              logging-kibana-ops

(In this example there are no overlapping routes.)
