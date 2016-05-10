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
from source and deploying. Normally existing ImageStreams are deleted
at installation to enable redeployment with different images. To prevent
your customized ImageStreams from being deleted, ensure that they are not
labeled with `logging-infra=support` like those generated by the deployer.

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

If you need to upgrade your EFK stack with new images and new features, you can
run the Deployer in `upgrade` mode.

    $ oc new-app logging-deployer-template \
           -p KIBANA_HOSTNAME=kibana.example.com \
           -p ES_CLUSTER_SIZE=1 \
           -p PUBLIC_MASTER_URL=https://localhost:8443 \
           -p MODE=upgrade

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
  If you had not previously done a uuid migration after a manual upgrade, you will
  still need to perform that with `MODE=migrate` while your Elasticsearch instances
  are running.

  This only impacts non-operations logs, operations logs will appear the
  same as in previous versions. There should be minimal performance impact to ES
  while running this and it will not perform an install.

## EFK Health

Determining the health of an EFK deployment and if it is running can be assessed
by running the `check-EFK-running.sh` and `check-logs.sh` [e2e tests](hack/testing/).
Additionally, you can do the following:

### Fluentd

Check Fluentd logs for the message that it has read in its config file:
```
2016-02-19 20:40:44 +0000 [info]: reading config file path="/etc/fluent/fluent.conf"
```

After that, you can verify that fluentd has been able to start reading in log files
by checking the contents of `/var/log/node.log.pos` and `/var/log/es-containers.log.pos`.
node.log.pos will keep track of the placement in syslog log files and es-containers.log.pos
will keep track of the placement in the docker log files (/var/log/containers).

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
