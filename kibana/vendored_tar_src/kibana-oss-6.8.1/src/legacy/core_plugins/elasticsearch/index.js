'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

exports.default = function (kibana) {
  return new kibana.Plugin({
    require: ['kibana'],
    config(Joi) {
      const sslSchema = Joi.object({
        verificationMode: Joi.string().valid('none', 'certificate', 'full').default('full'),
        certificateAuthorities: Joi.array().single().items(Joi.string()),
        certificate: Joi.string(),
        key: Joi.string(),
        keyPassphrase: Joi.string(),
        alwaysPresentCertificate: Joi.boolean().default(false)
      }).default();

      return Joi.object({
        enabled: Joi.boolean().default(true),
        sniffOnStart: Joi.boolean().default(false),
        sniffInterval: Joi.number().allow(false).default(false),
        sniffOnConnectionFault: Joi.boolean().default(false),
        hosts: Joi.array().items(Joi.string().uri({ scheme: ['http', 'https'] })).single().default('http://localhost:9200'),
        preserveHost: Joi.boolean().default(true),
        username: Joi.string(),
        password: Joi.string(),
        shardTimeout: Joi.number().default(30000),
        requestTimeout: Joi.number().default(30000),
        requestHeadersWhitelist: Joi.array().items().single().default(DEFAULT_REQUEST_HEADERS),
        customHeaders: Joi.object().default({}),
        pingTimeout: Joi.number().default(Joi.ref('requestTimeout')),
        startupTimeout: Joi.number().default(5000),
        logQueries: Joi.boolean().default(false),
        ssl: sslSchema,
        apiVersion: Joi.string().default('6.7'),
        healthCheck: Joi.object({
          delay: Joi.number().default(2500)
        }).default(),
        tribe: Joi.object({
          sniffOnStart: Joi.boolean().default(false),
          sniffInterval: Joi.number().allow(false).default(false),
          sniffOnConnectionFault: Joi.boolean().default(false),
          hosts: Joi.array().items(Joi.string().uri({ scheme: ['http', 'https'] })).single(),
          preserveHost: Joi.boolean().default(true),
          username: Joi.string(),
          password: Joi.string(),
          shardTimeout: Joi.number().default(0),
          requestTimeout: Joi.number().default(30000),
          requestHeadersWhitelist: Joi.array().items().single().default(DEFAULT_REQUEST_HEADERS),
          customHeaders: Joi.object().default({}),
          pingTimeout: Joi.number().default(Joi.ref('requestTimeout')),
          startupTimeout: Joi.number().default(5000),
          logQueries: Joi.boolean().default(false),
          ssl: sslSchema,
          apiVersion: Joi.string().default('master')
        }).default()
      }).default();
    },

    deprecations({ rename }) {
      const sslVerify = basePath => {
        const getKey = path => {
          return (0, _lodash.compact)([basePath, path]).join('.');
        };

        return (settings, log) => {
          const sslSettings = (0, _lodash.get)(settings, getKey('ssl'));

          if (!(0, _lodash.has)(sslSettings, 'verify')) {
            return;
          }

          const verificationMode = (0, _lodash.get)(sslSettings, 'verify') ? 'full' : 'none';
          (0, _lodash.set)(sslSettings, 'verificationMode', verificationMode);
          (0, _utils.unset)(sslSettings, 'verify');

          log(`Config key "${getKey('ssl.verify')}" is deprecated. It has been replaced with "${getKey('ssl.verificationMode')}"`);
        };
      };

      return [rename('ssl.ca', 'ssl.certificateAuthorities'), rename('ssl.cert', 'ssl.certificate'), rename('url', 'hosts'), sslVerify(), rename('tribe.ssl.ca', 'tribe.ssl.certificateAuthorities'), rename('tribe.ssl.cert', 'tribe.ssl.certificate'), sslVerify('tribe'), (settings = {}, log) => {
        const tribe = (0, _lodash.get)(settings, 'tribe');
        if (!tribe) {
          return;
        }
        const deprecatedUrl = (0, _lodash.get)(settings, 'tribe.url');
        if (deprecatedUrl) {
          (0, _lodash.set)(settings, 'tribe.hosts', [deprecatedUrl]);
          (0, _utils.unset)(settings(tribe.url));
        }
        const tribeKeys = Object.keys(tribe);
        if (tribeKeys.length > 0) {
          const keyList = tribeKeys.map(k => `"elasticsearch.tribe.${k}"`).join(',');
          log(`Config keys [${keyList}] are deprecated. Tribe nodes will be removed in 7.0 and should be replaced ` + `with Cross-Cluster-Search.`);
        }
      }];
    },

    uiExports: {
      injectDefaultVars(server, options) {
        return {
          esRequestTimeout: options.requestTimeout,
          esShardTimeout: options.shardTimeout,
          esApiVersion: options.apiVersion,
          esDataIsTribe: (0, _lodash.get)(options, 'tribe.hosts.length') ? true : false
        };
      }
    },

    init(server) {
      const clusters = (0, _create_clusters.createClusters)(server);

      server.expose('getCluster', clusters.get);
      server.expose('createCluster', clusters.create);

      server.expose('filterHeaders', _filter_headers2.default);
      server.expose('ElasticsearchClientLogging', (0, _client_logger.clientLogger)(server));

      (0, _create_data_cluster.createDataCluster)(server);
      (0, _create_admin_cluster.createAdminCluster)(server);

      (0, _create_proxy.createProxy)(server);

      // Set up the health check service and start it.
      const { start, waitUntilReady } = (0, _health_check2.default)(this, server);
      server.expose('waitUntilReady', waitUntilReady);
      start();
    }
  });
};

var _lodash = require('lodash');

var _utils = require('../../../utils');

var _health_check = require('./lib/health_check');

var _health_check2 = _interopRequireDefault(_health_check);

var _create_data_cluster = require('./lib/create_data_cluster');

var _create_admin_cluster = require('./lib/create_admin_cluster');

var _client_logger = require('./lib/client_logger');

var _create_clusters = require('./lib/create_clusters');

var _create_proxy = require('./lib/create_proxy');

var _filter_headers = require('./lib/filter_headers');

var _filter_headers2 = _interopRequireDefault(_filter_headers);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const DEFAULT_REQUEST_HEADERS = ['authorization']; /*
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

module.exports = exports['default'];