'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.registerTutorials = registerTutorials;

var _system_logs = require('./system_logs');

var _system_metrics = require('./system_metrics');

var _apache_logs = require('./apache_logs');

var _apache_metrics = require('./apache_metrics');

var _elasticsearch_logs = require('./elasticsearch_logs');

var _iis_logs = require('./iis_logs');

var _kafka_logs = require('./kafka_logs');

var _logstash_logs = require('./logstash_logs');

var _nginx_logs = require('./nginx_logs');

var _nginx_metrics = require('./nginx_metrics');

var _mysql_logs = require('./mysql_logs');

var _mysql_metrics = require('./mysql_metrics');

var _mongodb_metrics = require('./mongodb_metrics');

var _osquery_logs = require('./osquery_logs');

var _php_fpm_metrics = require('./php_fpm_metrics');

var _postgresql_metrics = require('./postgresql_metrics');

var _postgresql_logs = require('./postgresql_logs');

var _rabbitmq_metrics = require('./rabbitmq_metrics');

var _redis_logs = require('./redis_logs');

var _redis_metrics = require('./redis_metrics');

var _suricata_logs = require('./suricata_logs');

var _docker_metrics = require('./docker_metrics');

var _kubernetes_metrics = require('./kubernetes_metrics');

var _uwsgi_metrics = require('./uwsgi_metrics');

var _netflow = require('./netflow');

var _traefik_logs = require('./traefik_logs');

var _apm = require('./apm');

var _ceph_metrics = require('./ceph_metrics');

var _aerospike_metrics = require('./aerospike_metrics');

var _couchbase_metrics = require('./couchbase_metrics');

var _dropwizard_metrics = require('./dropwizard_metrics');

var _elasticsearch_metrics = require('./elasticsearch_metrics');

var _etcd_metrics = require('./etcd_metrics');

var _haproxy_metrics = require('./haproxy_metrics');

var _kafka_metrics = require('./kafka_metrics');

var _kibana_metrics = require('./kibana_metrics');

var _memcached_metrics = require('./memcached_metrics');

var _munin_metrics = require('./munin_metrics');

var _vsphere_metrics = require('./vsphere_metrics');

var _windows_metrics = require('./windows_metrics');

var _golang_metrics = require('./golang_metrics');

var _logstash_metrics = require('./logstash_metrics');

var _prometheus_metrics = require('./prometheus_metrics');

var _zookeeper_metrics = require('./zookeeper_metrics');

var _uptime_monitors = require('./uptime_monitors');

function registerTutorials(server) {
  server.registerTutorial(_system_logs.systemLogsSpecProvider);
  server.registerTutorial(_system_metrics.systemMetricsSpecProvider);
  server.registerTutorial(_apache_logs.apacheLogsSpecProvider);
  server.registerTutorial(_apache_metrics.apacheMetricsSpecProvider);
  server.registerTutorial(_elasticsearch_logs.elasticsearchLogsSpecProvider);
  server.registerTutorial(_iis_logs.iisLogsSpecProvider);
  server.registerTutorial(_kafka_logs.kafkaLogsSpecProvider);
  server.registerTutorial(_logstash_logs.logstashLogsSpecProvider);
  server.registerTutorial(_nginx_logs.nginxLogsSpecProvider);
  server.registerTutorial(_nginx_metrics.nginxMetricsSpecProvider);
  server.registerTutorial(_mysql_logs.mysqlLogsSpecProvider);
  server.registerTutorial(_mysql_metrics.mysqlMetricsSpecProvider);
  server.registerTutorial(_mongodb_metrics.mongodbMetricsSpecProvider);
  server.registerTutorial(_osquery_logs.osqueryLogsSpecProvider);
  server.registerTutorial(_php_fpm_metrics.phpfpmMetricsSpecProvider);
  server.registerTutorial(_postgresql_metrics.postgresqlMetricsSpecProvider);
  server.registerTutorial(_postgresql_logs.postgresqlLogsSpecProvider);
  server.registerTutorial(_rabbitmq_metrics.rabbitmqMetricsSpecProvider);
  server.registerTutorial(_redis_logs.redisLogsSpecProvider);
  server.registerTutorial(_redis_metrics.redisMetricsSpecProvider);
  server.registerTutorial(_suricata_logs.suricataLogsSpecProvider);
  server.registerTutorial(_docker_metrics.dockerMetricsSpecProvider);
  server.registerTutorial(_kubernetes_metrics.kubernetesMetricsSpecProvider);
  server.registerTutorial(_uwsgi_metrics.uwsgiMetricsSpecProvider);
  server.registerTutorial(_netflow.netflowSpecProvider);
  server.registerTutorial(_traefik_logs.traefikLogsSpecProvider);
  server.registerTutorial(_apm.apmSpecProvider);
  server.registerTutorial(_ceph_metrics.cephMetricsSpecProvider);
  server.registerTutorial(_aerospike_metrics.aerospikeMetricsSpecProvider);
  server.registerTutorial(_couchbase_metrics.couchbaseMetricsSpecProvider);
  server.registerTutorial(_dropwizard_metrics.dropwizardMetricsSpecProvider);
  server.registerTutorial(_elasticsearch_metrics.elasticsearchMetricsSpecProvider);
  server.registerTutorial(_etcd_metrics.etcdMetricsSpecProvider);
  server.registerTutorial(_haproxy_metrics.haproxyMetricsSpecProvider);
  server.registerTutorial(_kafka_metrics.kafkaMetricsSpecProvider);
  server.registerTutorial(_kibana_metrics.kibanaMetricsSpecProvider);
  server.registerTutorial(_memcached_metrics.memcachedMetricsSpecProvider);
  server.registerTutorial(_munin_metrics.muninMetricsSpecProvider);
  server.registerTutorial(_vsphere_metrics.vSphereMetricsSpecProvider);
  server.registerTutorial(_windows_metrics.windowsMetricsSpecProvider);
  server.registerTutorial(_golang_metrics.golangMetricsSpecProvider);
  server.registerTutorial(_logstash_metrics.logstashMetricsSpecProvider);
  server.registerTutorial(_prometheus_metrics.prometheusMetricsSpecProvider);
  server.registerTutorial(_zookeeper_metrics.zookeeperMetricsSpecProvider);
  server.registerTutorial(_uptime_monitors.uptimeMonitorsSpecProvider);
} /*
   * Licensed to Elasticsearch B.V. under one or more contributor
   * license agreements. See the NOTICE file distributed with
   * this work for additional information regarding copyright
   * ownership. Elasticsearch B.V. licenses this file to you under
   * the Apache License, Version 2.0 (the "License"); you may
   * not use this file except in compliance with the License.
   * You may obtain a copy of the License at
   *
   *    http://www.apache.org/licenses/LICENSE-2.0
   *
   * Unless required by applicable law or agreed to in writing,
   * software distributed under the License is distributed on an
   * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
   * KIND, either express or implied.  See the License for the
   * specific language governing permissions and limitations
   * under the License.
   */