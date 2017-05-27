# Origin-Aggregated-Logging [![Build Status](https://ci.openshift.redhat.com/jenkins/buildStatus/icon?job=test-origin-aggregated-logging)](https://ci.openshift.redhat.com/jenkins/job/test-origin-aggregated-logging)

This repo contains the image definitions for the components of the logging
stack as well as tools for building and deploying them.  The logging subsystem
consists of multiple [components](#Components) abbreviated as the "EFK"
stack: Elasticsearch, Fluentd, Kibana.

The primary features this integration provides:

* Multitenant support to isolate logs from various project namespaces
* Openshift OAuth2 integration
* Historical log discovery and visualization
* Log aggregation of pod and node logs

Information to build the images from github source using an OpenShift
Origin deployment is found [here](HACKING.md).

NOTE: If you are running OpenShift Origin using the
[All-In-One docker container](https://docs.openshift.org/latest/getting_started/administrators.html#running-in-a-docker-container)
method, you MUST add `-v /var/log:/var/log` to the `docker` command line.
OpenShift must have access to the container logs in order for Fluentd to read
and process them.

## Components

The logging subsystem consists of multiple components commonly abbreviated
as the "ELK" stack (though modified here to be the "EFK" stack).

### Elasticsearch

Elasticsearch is a Lucene-based indexing object store into which logs
are fed. Logs for node services and all containers in the cluster are
fed into one deployed cluster. The Elasticsearch cluster should be deployed
with redundancy and persistent storage for scale and high availability.

### Fluentd

Fluentd is responsible for gathering log entries from nodes, enriching
them with metadata, and feeding them into Elasticsearch.

### Kibana

Kibana presents a web UI for browsing and visualizing logs in Elasticsearch.

### Logging auth proxy

In order to authenticate the Kibana user against OpenShift's Oauth2, a
proxy is required that runs in front of Kibana.

### Curator

Curator allows the admin to remove old indices from Elasticsearch on a per-project
basis.

## EFK Health

Determining the health of an EFK deployment and if it is running can be assessed
by running the `check-EFK-running.sh` and `check-logs.sh` [e2e tests](hack/testing/).
Additionally, see [Checking EFK Health](#checking-efk-health) below.

## Further Documentation

* [Using Kibana](#using-kibana)
* [Adjusting Elasticsearch After Deployment](#adjusting-elasticsearch-after-deployment)
* [Checking EFK Health](#checking-efk-health)
* [Troubleshooting](#troubleshooting)

## Using Kibana

The subject of using Kibana in general is covered in that [project's
documentation](https://www.elastic.co/guide/en/kibana/4.5/discover.html).
Here is some information specific to the aggregated logging deployment.

1. Login is performed via OAuth2, as with the web console. The default certificate
authentication used for the admin user isn't available, but you can create
other users and make them cluster admins.
2. Kibana and Elasticsearch have been customized to display logs only
to users that have access to the projects the logs came from. So if you login
and have no access to anything, be sure your user has access to at least one
project. Cluster admin users should have access to all project logs as
well as host logs.
3. To do anything with Elasticsearch and Kibana, Kibana has to have
defined some index patterns that match indices being recorded in
Elasticsearch. This should already be done for you, but you should be
aware how these work in case you want to customize anything. When logs
from applications in a project are recorded, they are indexed by project
name and date in the format `project.name.YYYY-MM-DD`. For matching a project's
logs for all dates, an index pattern will be defined in Kibana for each
project which looks like `project.name.*`.
4. When first visiting Kibana, the first page directs you to create
an index pattern.  In general this should not be necessary and you can
just click the "Discover" tab and choose a project index pattern to see
logs. If there are no logs yet for a project, you won't get any results;
keep in mind also that the default time interval for retrieving logs is
15 minutes and you will need to adjust it to find logs older than that.
5. Unfortunately there is no way to stream logs as they are created at
this time.
6. By default, only a `cluster-admin` user can view logs contained within
the `.operations.*` index. To allow a `cluster-reader` user or a `cluster-admin`
user to be able to view these logs, run `$ oc edit configmap/logging-elasticsearch`,
change the value of `openshift.operations.allow_cluster_reader` to `true` and
restart your ES cluster.

## Adjusting Elasticsearch After Deployment

If you need to change the Elasticsearch cluster size after deployment,
DO NOT just scale existing deployments up or down. Elasticsearch cannot
scale by ordinary Kubernetes mechanisms, as explained above. Each
instance requires its own storage, and thus under current capabilities,
its own deployment. The ansible deployer defined a template
`logging-es-template` which can be used to create new Elasticsearch
deployments.

Adjusting the scale of the Elasticsearch cluster typically requires
adjusting cluster parameters that vary by cluster size. [Elastic
documentation discusses these issues](https://www.elastic.co/guide/en/elasticsearch/guide/current/_important_configuration_changes.html)
and the corresponding parameters are coded as environment variables in
the existing deployments and parameters in the deployment template
(mentioned in the [Settings](#settings) section). The ansible deployer
chooses sensible defaults based on cluster size. These should be
adjusted for both new and existing deployments when changing the cluster
size.

Changing cluster parameters (or any parameters/secrets, really) requires
re-deploying the instances. In order to minimize resynchronization
between the instances as they are restarted, we advise halting traffic to
Elasticsearch and then taking down the entire cluster for maintenance. No
logs will be lost; Fluentd simply blocks until the cluster returns.

Halting traffic to Elasticsearch requires scaling down Kibana and removing node labels for Fluentd:

    $ oc label node --all logging-infra-
    $ oc scale rc/logging-kibana-1 --replicas=0

Next scale all of the Elasticsearch deployments to 0 similarly.

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


## Checking EFK Health

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
[2016-09-07 19:39:15,935][INFO ][node                     ] [Kofi Whitemane] version[2.3.5], pid[1], build[90f439f/2016-07-27T10:36:52Z]
[2016-09-07 19:39:15,936][INFO ][node                     ] [Kofi Whitemane] initializing ...
[2016-09-07 19:39:16,857][INFO ][plugins                  ] [Kofi Whitemane] modules [reindex, lang-expression, lang-groovy], plugins [search-guard-ssl, openshift-elasticsearch, cloud-kubernetes, search-guard-2], sites []
[2016-09-07 19:39:16,895][INFO ][env                      ] [Kofi Whitemane] using [1] data paths, mounts [[/elasticsearch/persistent (/dev/xvda2)]], net usable_space [15.8gb], net total_space [24.9gb], spins? [possibly], types [xfs]
[2016-09-07 19:39:16,895][INFO ][env                      ] [Kofi Whitemane] heap size [3.9gb], compressed ordinary object pointers [true]
[2016-09-07 19:39:17,502][INFO ][http                     ] [Kofi Whitemane] Using [org.elasticsearch.http.netty.NettyHttpServerTransport] as http transport, overridden by [search-guard2]
[2016-09-07 19:39:17,647][INFO ][transport                ] [Kofi Whitemane] Using [com.floragunn.searchguard.transport.SearchGuardTransportService] as transport service, overridden by [search-guard2]
[2016-09-07 19:39:17,647][INFO ][transport                ] [Kofi Whitemane] Using [com.floragunn.searchguard.ssl.transport.SearchGuardSSLNettyTransport] as transport, overridden by [search-guard-ssl]
[2016-09-07 19:39:19,019][INFO ][plugins                  ] [Johnny Blaze] modules [], plugins [search-guard-ssl, search-guard2], sites []
[2016-09-07 19:39:19,098][INFO ][transport                ] [Johnny Blaze] Using [com.floragunn.searchguard.ssl.transport.SearchGuardSSLNettyTransport] as transport, overridden by [search-guard-ssl]
[2016-09-07 19:39:19,439][INFO ][node                     ] [Kofi Whitemane] initialized
[2016-09-07 19:39:19,439][INFO ][node                     ] [Kofi Whitemane] starting ...
[2016-09-07 19:39:19,469][INFO ][discovery                ] [Kofi Whitemane] logging-es/SCD5jpJBQO2Obz1uBZQGtQ
[2016-09-07 19:39:19,937][INFO ][io.fabric8.elasticsearch.discovery.kubernetes.KubernetesUnicastHostsProvider] [Kofi Whitemane] adding endpoint /172.17.0.3, transport_address 172.17.0.3:9300
[2016-09-07 19:39:21,486][INFO ][io.fabric8.elasticsearch.discovery.kubernetes.KubernetesUnicastHostsProvider] [Kofi Whitemane] adding endpoint /172.17.0.3, transport_address 172.17.0.3:9300
[2016-09-07 19:39:23,004][INFO ][io.fabric8.elasticsearch.discovery.kubernetes.KubernetesUnicastHostsProvider] [Kofi Whitemane] adding endpoint /172.17.0.3, transport_address 172.17.0.3:9300
[2016-09-07 19:39:23,063][INFO ][cluster.service          ] [Kofi Whitemane] new_master {Kofi Whitemane}{SCD5jpJBQO2Obz1uBZQGtQ}{172.17.0.3}{logging-es-cluster/172.17.0.3:9300}{master=true}, reason: zen-disco-join(elected_as_master, [0] joins received)
[2016-09-07 19:39:23,120][INFO ][http                     ] [Kofi Whitemane] publish_address {logging-es/172.30.232.65:9200}, bound_addresses {[::]:9200}
[2016-09-07 19:39:23,120][INFO ][node                     ] [Kofi Whitemane] started
[2016-09-07 19:39:23,375][INFO ][gateway                  ] [Kofi Whitemane] recovered [0] indices into cluster_state
```
At this point, you know that ES is currently up and running.

If you see an ERROR message like the following from `com.floragunn.searchguard.auth.BackendRegistry` you can ignore it as long as it doesn't persist for a long time.
This is due to the SearchGuard plugin not yet being initialized by the Openshift-Elasticsearch-Plugin. It will print that message any time it receives a request without
having been initialized. While you can ignore stack traces from Search Guard it is important to still review them to determine why may ES may not have started up,
especially if the SearchGuard stack trace is repeated multiple times:
```
[ERROR][com.floragunn.searchguard.auth.BackendRegistry] Not yet initialized
```

Another message you can ignore is the following WARN message from `io.fabric8.elasticsearch.plugin.acl.DynamicACLFilter`, again, so long as it doesn't persist for a long time.
This message comes from the Openshift-Elasticsearch-Plugin attempting to initialize SearchGuard's configuration, however the Elasticsearch cluster is not yet in a 'yellow' state:
```
[WARN ][io.fabric8.elasticsearch.plugin.acl.DynamicACLFilter] [Kofi Whitemane] Trying to seed ACL when ES has not not yet started: 'None of the configured nodes are available: [{#transport#-1}{127.0.0.1}{localhost/127.0.0.1:9300}]'
```

Since Fluentd and Kibana both talk to Elasticsearch, the Elasticsearch logs are a good place to go for
verifying that connections are active.

You can see what indices have been created by Fluentd pushing logs to Elasticsearch:
```
[2016-09-07 19:39:25,875][INFO ][cluster.metadata         ] [Kofi Whitemane] [.searchguard.logging-es-l31pwce4-3-chb8d] creating index, cause [api], templates [], shards [1]/[0], mappings []
[2016-09-07 19:39:25,934][INFO ][cluster.routing.allocation] [Kofi Whitemane] Cluster health status changed from [RED] to [YELLOW] (reason: [shards started [[.searchguard.logging-es-l31pwce4-3-chb8d][0]] ...]).
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
{"type":"log","@timestamp":"2016-09-07T20:07:31+00:00","tags":["listening","info"],"pid":8,"message":"Server running at http://0.0.0.0:5601"}
{"type":"log","@timestamp":"2016-09-07T20:07:31+00:00","tags":["status","plugin:elasticsearch","info"],"pid":8,"name":"plugin:elasticsearch","state":"green","message":"Status changed from yellow to green - Kibana index ready","prevState":"yellow","prevMsg":"Waiting for Elasticsearch"}
```

## Troubleshooting

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
connected to from within a pod, this generally indicates a system
firewall/network problem and should be debugged as such.

### Kibana access shows 503 error

If everything is deployed but visiting Kibana results in a proxy
error, then one of the following things is likely to be the issue.

First, Kibana might not actually have any pods that are recognized
as running. If Elasticsearch is slow in starting up, Kibana may
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