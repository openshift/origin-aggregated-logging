# Origin-Aggregated-Logging

This repo contains the image definitions of the components of the logging
stack as well as tools for building and deploying them.

To generate the necessary images from github source in your OpenShift
Origin deployment, follow directions below.

To deploy the components from built or supplied images, see the
[deployer](./deployment).

NOTE: If you are running OpenShift Origin using the
[All-In-One docker container](https://docs.openshift.org/latest/getting_started/administrators.html#running-in-a-docker-container)
method, you MUST add `-v /var/log:/var/log` to the `docker` command line.
OpenShift must have access to the container logs in order for Fluentd to read
and process them.

## Components

The logging subsystem consists of multiple components commonly abbreviated
as the "ELK" stack (though modified here to be the "EFK" stack).

### ElasticSearch

ElasticSearch is a Lucene-based indexing object store into which all logs
are fed. It should be deployed with redundancy, can be scaled up using
more replicas, and should use persistent storage.

### Fluentd

Fluentd is responsible for gathering log entries from nodes, enriching
them with metadata, and feeding them into ElasticSearch.

### Kibana

Kibana presents a web UI for browsing and visualizing logs in ElasticSearch.

### Logging auth proxy

In order to authenticate the Kibana user against OpenShift's Oauth2, a
proxy is required that runs in front of Kibana.

### Deployer

The deployer enables the user to generate all of the necessary
key/certs/secrets and deploy all of the components in concert.

#### Curator

Curator allows the admin to remove old indices from Elasticsearch on a per-project
basis.  The pod will read its configuration from a mounted yaml file that
is structured like this:

    $PROJECT_NAME:
      $ACTION:
        $UNIT: $VALUE

    $PROJECT_NAME:
      $ACTION:
        $UNIT: $VALUE
     ...

* $PROJECT_NAME - the actual name of a project - "myapp-devel"
** For operations logs, use the name `.operations` as the project name
* $ACTION - the action to take - currently only "delete"
* $UNIT - one of "days", "weeks", or "months"
* $VALUE - an integer for the number of units
* `.defaults` - use `.defaults` as the $PROJECT_NAME to set the defaults for
projects that are not specified
** runhour: NUMBER - hour of the day in 24 hour format at which to run the
curator jobs
** runminute: NUMBER - minute of the hour at which to run the curator jobs

For example, using::

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

Every day, curator will run, and will delete indices in the myapp-dev
project older than 1 day, and indices in the myapp-qe project older than 1
week.  All other projects will have their indices deleted after they are 30
days old.  The curator jobs will run at midnight every day.

*WARNING*: Using `months` as the unit

When you use month based trimming, curator starts counting at the _first_ day of
the current month, not the _current_ day of the current month.  For example, if
today is April 15, and you want to delete indices that are 2 months older than
today (`delete: months: 2`), curator doesn't delete indices that are dated
older than February 15, it deletes indices older than _February 1_.  That is,
it goes back to the first day of the current month, _then_ goes back two whole
months from that date.
If you want to be exact with curator, it is best to use `days` e.g. `delete: days: 30`
[Curator issue](https://github.com/elastic/curator/issues/569)

To create the curator configuration, do the following:

Create a yaml file with your configuration settings using your favorite editor.
Next create a secret from your created yaml file:
`oc secrets new index-management settings=</path/to/your/yaml/file>`

Then mount your created secret as a volume in your Curator DC:
`oc volumes dc/logging-curator --add --type=secret --secret-name=index-management --mount-path=/etc/curator --name=index-management --overwrite`

The mount-path value e.g. `/etc/curator` must match the `CURATOR_CONF_LOCATION`
in the environment.

You can also specify default values for the run hour, run minute, and age in
days of the indices when processing the curator template.  Use
`CURATOR_RUN_HOUR` and `CURATOR_RUN_MINUTE` to set the default runhour and
runminute, and use `CURATOR_DEFAULT_DAYS` to set the default index age.

# Defining local builds

Choose the project you want to hold your logging infrastructure. It can be
any project.

Instantiate the [dev-builds template](hack/templates/dev-builds.yaml)
to define BuildConfigs for all images and ImageStreams to hold their
output. You can do this before or after deployment, but before is
recommended. A logging deployment defines the same ImageStreams, so it
is normal to see errors about already-defined ImageStreams when building
from source and deploying.

The template has parameters to specify the repository and branch to use
for the builds. The defaults are for origin master. To develop your own
images, you can specify your own repos and branches as needed.

A word about the openshift-auth-proxy: it depends on the "node" base
image, which is intended to be the DockerHub nodejs base image. If you
have defined all the standard templates, they include a nodejs builder image
that is also called "node", and this will be used instead of the intended
base image, causing the build to fail. You can delete it to resolve this
problem:

    oc delete is/node -n openshift

The builds should start once defined; if any fail, you can retry them with:

    oc start-build <component>

e.g.

    oc start-build openshift-auth-proxy

Once these builds complete successfully the ImageStreams will be
populated and you can use them for a deployment. You will need to
specify an `INDEX_PREFIX` pointing to their registry location, which
you can get from:

    $ oc get is
    NAME                    DOCKER REPO
    logging-deployment      172.30.90.128:5000/logs/logging-deployment

In order to run a deployment with these images, you would process the
[deployer template](deployment/deployer.yaml) with the
`IMAGE_PREFIX=172.30.90.128:5000/logs/` parameter. Proceed to the
[deployer instructions](./deployment) to run a deployment.

## Running the deployer script locally

When developing the deployer, it is fairly tedious to rebuild the image
and redeploy it just for tiny iterative changes.  The deployer script
is designed to be run either in the deployer image or directly. It
requires the openshift and oc binaries as well as the Java 8 JDK. When
run directly, it will use your current client context to create all
the objects, but you must still specify at least the PROJECT env var in
order to create everything with the right parameters. E.g.:

    cd deployment
    PROJECT=logging ./run.sh

There are a number of env vars this script looks at which are useful
when running directly; check the script headers for details.

## Throttling logs in Fluentd

For projects that are especially verbose, an administrator can throttle
down the rate at which the logs are read in by Fluentd at a time before being
processed. Note: this means that aggregated logs for the configured projects
could fall behind and even be deleted if the pod were deleted before Fluentd
caught up.  

To tell Fluentd which projects it should be restricting you will
need to do the following:

Create a yaml file that contains project names and the desired rate at which
logs are read in. (Default is 1000)
```
logging:
  read_lines_limit: 500

test-project:
  read_lines_limit: 10

.operations:
  read_lines_limit: 100
```

Create a secret providing this file as the source
```
oc secrets new fluentd-throttle settings=</path/to/your/yaml>
```

Mount the created secret to your Fluentd container
```
oc volumes dc/logging-fluentd --add --type=secret --secret-name=fluentd-throttle --mount-path=/etc/throttle-settings --name=throttle-settings --overwrite
```

## Have Fluentd send logs to another Elasticsearch

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

To set the parameters::

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

## Upgrading your EFK stack

If you need to upgrade your EFK stack with new images, you'll need to take the
following steps to safely upgrade with minimal disruption to your log data.

Scale down your Fluentd instances to 0.

    $ oc scale dc/logging-fluentd --replicas=0

Wait until they have properly terminated, this gives them time to properly
flush their current buffer and send any logs they were processing to
Elasticsearch. This helps prevent loss of data.

You can scale down your Kibana instances at this time as well.

    $ oc scale dc/logging-kibana --replicas=0
    $ oc scale dc/logging-kibana-ops --replicas=0 (if applicable)

Once your Fluentd and Kibana pods are confirmed to be terminated we can safely
scale down the Elasticsearch pods.

    $ oc scale dc/logging-es-{unique_name} --replicas=0
    $ oc scale dc/logging-es-ops-{unique_name} --replicas=0 (if applicable)

Once your ES pods are confirmed to be terminated we can now pull in the latest
EFK images to use as described [here](https://docs.openshift.org/latest/install_config/upgrading/manual_upgrades.html#importing-the-latest-images),
replacing the default namespace with the namespace where logging was installed.

With the latest images in your repository we can now begin to scale back up.
We want to scale ES back up incrementally so that the cluster has time to rebuild.

    $ oc scale dc/logging-es-{unique_name} --replicas=1

We want to tail the logs of the resulting pod to ensure that it was able to recover
its indices correctly and that there were no errors.  If that is successful, we
can then do the same for the operations cluster if one was previously used.

Once all ES nodes have recovered their indices, we can then scale it back up to
the size it was prior to doing maintenance. It is recommended to check the logs
of the ES members to verify that they have correctly joined the cluster and
recovered.

We can now scale Kibana and Fluentd back up to their previous state.  Since Fluentd
was shut down and allowed to push its remaining records to ES in the previous
steps it can now pick back up from where it left off with no loss of logs -- so long
as the log files that were not read in are still available on the node.
