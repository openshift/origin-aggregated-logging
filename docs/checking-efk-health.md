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

The following error is caused from using a headless services to provide Elasticsearch node discovery.  This log message is present when an Elasticsearch node boots and attempts to discover the
other members of the cluster before the Kublet is able to publish all the pod endpoints.

```
[2018-06-22T18:36:11,210][DEBUG][o.e.a.a.i.e.i.TransportIndicesExistsAction] [logging-es-data-master-x6fia9t2] no known master node, scheduling a retry
[2018-06-22T18:36:11,286][WARN ][o.e.d.z.UnicastZenPing   ] [logging-es-data-master-x6fia9t2] failed to resolve host [logging-es-cluster]
java.net.UnknownHostException: logging-es-cluster: Name or service not known
	at java.net.Inet6AddressImpl.lookupAllHostAddr(Native Method) ~[?:1.8.0_171]
	at java.net.InetAddress$2.lookupAllHostAddr(InetAddress.java:928) ~[?:1.8.0_171]
	at java.net.InetAddress.getAddressesFromNameService(InetAddress.java:1323) ~[?:1.8.0_171]
	at java.net.InetAddress.getAllByName0(InetAddress.java:1276) ~[?:1.8.0_171]
	at java.net.InetAddress.getAllByName(InetAddress.java:1192) ~[?:1.8.0_171]
	at java.net.InetAddress.getAllByName(InetAddress.java:1126) ~[?:1.8.0_171]
	at org.elasticsearch.transport.TcpTransport.parse(TcpTransport.java:911) ~[elasticsearch-5.6.9.jar:5.6.9]
	at org.elasticsearch.transport.TcpTransport.addressesFromString(TcpTransport.java:866) ~[elasticsearch-5.6.9.jar:5.6.9]
	at org.elasticsearch.transport.TransportService.addressesFromString(TransportService.java:701) ~[elasticsearch-5.6.9.jar:5.6.9]
	at org.elasticsearch.discovery.zen.UnicastZenPing.lambda$null$0(UnicastZenPing.java:212) ~[elasticsearch-5.6.9.jar:5.6.9]
	at java.util.concurrent.FutureTask.run(FutureTask.java:266) ~[?:1.8.0_171]
	at org.elasticsearch.common.util.concurrent.ThreadContext$ContextPreservingRunnable.run(ThreadContext.java:575) [elasticsearch-5.6.9.jar:5.6.9]
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149) [?:1.8.0_171]
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624) [?:1.8.0_171]
	at java.lang.Thread.run(Thread.java:748) [?:1.8.0_171]
```
This is an acceptable message unless the cluster is not able to elect a master or form a quorum. The election of a master is indicated by a mesage like:

```
[2018-06-22T18:36:14,337][INFO ][o.e.c.s.ClusterService   ] [logging-es-data-master-x6fia9t2] new_master {logging-es-data-master-x6fia9t2}{fEQ6fBt0QuGIC_JyPlLw_A}{GNaZBu9VS_OQcpkOBskfSw}{10.128.0.35}{10.128.0.35:9300}, reason: zen-disco-elected-as-master ([0] nodes joined)[, ]
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

See the [troubleshooting](./troubleshooting.md) documentation for additional information to resolving issues with a cluster-logging deployment.
