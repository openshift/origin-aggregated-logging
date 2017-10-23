# Allow Fluentd to secure forward to other Fluentd/Logstash

## Why?

* Currently we allow forwarding just to another unsecure Elasticsearch
* No easy way to ship off Fluentd collected logs for OSE to other log aggregators
* More simple to support single plugin to do this than adding a number of Fluentd output plugins

## How?

Ship Fluentd image with [fluent-plugin-secure-forward](https://github.com/tagomoris/fluent-plugin-secure-forward)
and provide a means to configure it with configmaps/environment variables.

Dockerfile:
```
RUN mkdir -p ${HOME} && \
    gem install --no-rdoc --no-ri \
      --conservative --minimal-deps \
      fluentd:${FLUENTD_VERSION} \
      'activesupport:<5' \
      fluent-plugin-kubernetes_metadata_filter \
      fluent-plugin-elasticsearch \
      fluent-plugin-flatten-hash \
      fluent-plugin-systemd \
      systemd-journal \
-     fluent-plugin-rewrite-tag-filter
+     fluent-plugin-rewrite-tag-filter \
+     fluent-plugin-secure-forward
```

configs.d/openshift/output-applications.conf:
```
<match **>
   @type copy
   @include output-es-config.conf
   @include ../user/output-extra-*.conf
   @include ../dynamic/es-copy-config.conf
+  @include ../user/secure-forward-config.conf
</match>
```

configs.d/openshift/output-operations.conf:
```
<match journal.system** system.var.log** **_default_** **_openshift_** **_openshift-infra_**>
  @type copy
  @include output-es-ops-config.conf
  @include ../user/output-ops-extra-*.conf
  @include ../dynamic/es-ops-copy-config.conf
+ @include ../user/secure-forward-config.conf
</match>
```

example secure-forward-config.conf:
```
<store>
  @type secure_forward

  self_hostname ${HOSTNAME}
  shared_key    secret_string

  secure yes
  # enable_strict_verification yes

  ca_cert_path /path/for/certificate/ca_cert.pem
  ca_private_key_path /path/for/certificate/ca_key.pem
  ca_private_key_passphrase passphrase # for private CA secret key

  <server>
    host server.fqdn.example.com  # or IP
    # port 24284
  </server>
  <server>
    host 203.0.113.8 # ip address to connect
    hostlabel server.fqdn.example.com # specify hostlabel for FQDN verification if ipaddress is used for host
  </server>
</store>
```

## Proposal

Begin to deprecate `ES_COPY` which allows us to simply forward a copy of our logs
to another, unsecured, Elasticsearch cluster. We will provide a way for customers
to configure and use the `Secure Forward` Fluentd plugin to enable them to integrate
logs from OSE into their current log aggregation solution.

With the intention to deprecate `ES_COPY`; we also need to provide a simple path
'upgrade' to using secure-forward

# Limitations

The customer would need to have something that can talk with the Fluentd plugin.

* (OSE) Fluentd => (external) Fluentd : would be done using the Secure Forward
input plugin.
* (OSE) Fluentd => (external) Logstash : it looks like Logstash has a Fluent codec
[1] that may be able to be used in conjunction with secure TCP configurations [2].
* (OSE) Fluentd => (external) Splunk : a customer would need to configure Fluentd
to sit in front of their Splunk instance and accept logs from our Fluentd and then
forward them on to Splunk using a Fluentd plugin [3][4]. E.g.
(OSE) Fluentd => (external) Fluentd => Splunk


[1] https://www.elastic.co/guide/en/logstash/current/plugins-codecs-fluent.html

[2] https://www.elastic.co/guide/en/logstash/current/plugins-inputs-tcp.html#ssl_enable

[3] https://github.com/parolkar/fluent-plugin-splunk

[4] https://github.com/gtrevg/fluent-plugin-splunk-ex

# Additional considerations

We should also have a means to limit the Aggregated Logging installation to only
be Fluentd that can forward logs to an external source. We would also need to
recognize this installation mode when doing upgrades, we can probably have an
annotation added to the Fluentd daemonset to indicate whether or not it was a
solo Fluentd installation.
