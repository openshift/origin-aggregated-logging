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
     ...

Every day, curator will run, and will delete indices in the myapp-dev
project older than 1 day, and indices in the myapp-qe project older than 1
week.

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
`oc secrets new index_management settings=</path/to/your/yaml/file>`

Then mount your created secret as a volume in your Curator DC:
`oc volumes dc/logging-curator --add --type=secret --secret-name=index_management --mount-path=/etc/curator --name=index_management --overwrite`

The mount-path value e.g. `/etc/curator` must match the `CURATOR_CONF_LOCATION`
in the environment.

By default curator will run at midnight and deletes logs older than 30 days.
The environment variables `CURATOR_CRON_HOUR` AND `CURATOR_CRON_MINUTE` can be
used to define another hour and minute while `DEFAULT_DAYS` will change the
default number of days logs will be kept for.

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
