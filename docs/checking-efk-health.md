# Checking EFK Health

Determining the health of an EFK deployment and if it is running
is described in the subsequent sections.

## Fluentd

Check Fluentd logs for the message that it has read in its config file:
```
2016-02-19 20:40:44 +0000 [info]: reading config file path="/etc/fluent/fluent.conf"
```

Verify that Fluentd has been able to start reading in log files
by checking the contents of `/var/log/es-containers.log.pos` and `/var/log/journal.pos`.
The `es-containers.log.pos` keeps track of where fluentd is in reading the docker log files (i.e `/var/log/containers`).  
The `/var/log/journal.pos` keeps track of where fluentd is in reading the journal.

You can view the journal starting at the location where fluentd last read it by using a command like the following (as root):

```
$ journalctl -c `cat /var/log/journal.pos`
```

## Elasticsearch

Elasticsearch logs provide information such as the number of indices it recovered upon starting up.
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
This indicates Elasticsearch is currently up and running.

Error message like the following from `com.floragunn.searchguard.auth.BackendRegistry` can be ignored as long as it does not persist for a long time.
This is due to the SearchGuard plugin not yet being initialized by the ***openshift-elasticsearch-plugin***. It will print that message any time it receives a request without
having been initialized. While you can ignore stack traces from Search Guard it is important to still review them to determine why Elasticsearch may not have started up,
especially if the SearchGuard stack trace is repeated multiple times:
```
[ERROR][com.floragunn.searchguard.auth.BackendRegistry] Not yet initialized
```

Another message that can be ignore is the following WARN message from `io.fabric8.elasticsearch.plugin.acl.DynamicACLFilter`, again, so long as it doesn't persist for a long time.
This message comes from the ***openshift-elasticsearch-plugin*** attempting to initialize SearchGuard's configuration, however the Elasticsearch cluster is not yet in a 'yellow' state:
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

## Kibana

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

# Troubleshooting

There are a number of common problems with logging deployment that have simple
explanations but do not present useful errors for troubleshooting.

## Looping login on Kibana

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

Follow the `openshift-ansible` instructions to re-run the `openshift_logging` role.
This will replace the oauthclient and your next successful login should not loop.

## "error":"invalid\_request" on login

When you visit Kibana directly and it redirects you to login, you instead
receive an error in the browser like the following:

     {"error":"invalid_request","error_description":"The request is missing a required parameter,
      includes an invalid parameter value, includes a parameter more than once, or is otherwise malformed."}

The reason for this is a mismatch between the OAuth2 client and server.
The return address for the client has to be in a whitelist for the server to
securely redirect back after logging in; if there is a mismatch, then this
cryptic error message is shown.

As above, this may be caused by an `oauthclient` entry lingering from a
previous deployment, in which case you can replace it:

    $ oc delete oauthclient/kibana-proxy

Follow the `openshift-ansible` instructions to re-run the `openshift_logging` role.
This will replace the `oauthclient`. Return to the Kibana URL and try again.  

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

## Deployment fails, RCs scaled to 0

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

## Image pull fails

If you specify an `openshift_logging_image_prefix` that results in images being defined that don't exist,
you will receive a corresponding error message, typically after creating the deployer.

    NAME                     READY     STATUS                                                                                       RESTARTS   AGE
    logging-fluentd-1ub9k    0/1       Error: image registry.access.redhat.com:5000/openshift3logging-fluentd:latest not found      0          1m

In this example, for the intended image name
`registry.access.redhat.com:5000/openshift3/logging-fluentd:latest`
the `openshift_logging_image_prefix` needed a trailing `/`.

Update the inventory file and follow the `openshift-ansible` instructions
to re-run the `openshift_logging` role.

## Can't resolve kubernetes.default.svc.cluster.local

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

## Can't connect to the master or services

If DNS resolution does not return at all or the address cannot be
connected to from within a pod (e.g. the fluentd pod), this generally
indicates a system firewall/network problem and should be debugged
as such.

## Kibana access shows 503 error

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
