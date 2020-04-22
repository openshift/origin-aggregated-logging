'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; }; /*
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

exports.default = function (kibana) {
  const modules = (0, _path.resolve)(__dirname, 'public/webpackShims/');
  const src = (0, _path.resolve)(__dirname, 'public/src/');

  const apps = [];
  return new kibana.Plugin({
    id: 'console',
    require: ['elasticsearch'],

    isEnabled(config) {
      // console must be disabled when tribe mode is configured
      return config.get('console.enabled') && !config.get('elasticsearch.tribe.hosts');
    },

    config: function (Joi) {
      return Joi.object({
        enabled: Joi.boolean().default(true),
        proxyFilter: Joi.array().items(Joi.string()).single().default(['.*']),
        ssl: Joi.object({
          verify: Joi.boolean()
        }).default(),
        proxyConfig: Joi.array().items(Joi.object().keys({
          match: Joi.object().keys({
            protocol: Joi.string().default('*'),
            host: Joi.string().default('*'),
            port: Joi.string().default('*'),
            path: Joi.string().default('*')
          }),

          timeout: Joi.number(),
          ssl: Joi.object().keys({
            verify: Joi.boolean(),
            ca: Joi.array().single().items(Joi.string()),
            cert: Joi.string(),
            key: Joi.string()
          }).default()
        })).default()
      }).default();
    },

    deprecations: function () {
      return [(settings, log) => {
        if ((0, _lodash.has)(settings, 'proxyConfig')) {
          log('Config key "proxyConfig" is deprecated. Configuration can be inferred from the "elasticsearch" settings');
        }
      }];
    },

    init: function (server, options) {
      server.expose('addExtensionSpecFilePath', _spec.addExtensionSpecFilePath);
      if (options.ssl && options.ssl.verify) {
        throw new Error('sense.ssl.verify is no longer supported.');
      }

      const config = server.config();
      const { filterHeaders } = server.plugins.elasticsearch;
      const proxyConfigCollection = new _server2.ProxyConfigCollection(options.proxyConfig);
      const proxyPathFilters = options.proxyFilter.map(str => new RegExp(str));

      server.route((0, _server2.createProxyRoute)({
        baseUrl: (0, _lodash.head)(config.get('elasticsearch.hosts')),
        pathFilters: proxyPathFilters,
        getConfigForReq(req, uri) {
          const whitelist = config.get('elasticsearch.requestHeadersWhitelist');
          const filteredHeaders = filterHeaders(req.headers, whitelist);
          const headers = (0, _set_headers2.default)(filteredHeaders, config.get('elasticsearch.customHeaders'));

          if (!(0, _lodash.isEmpty)(config.get('console.proxyConfig'))) {
            return _extends({}, proxyConfigCollection.configForUri(uri), {
              headers
            });
          }

          return _extends({}, (0, _server2.getElasticsearchProxyConfig)(server), {
            headers
          });
        }
      }));

      server.route({
        path: '/api/console/api_server',
        method: ['GET', 'POST'],
        handler: function (req, h) {
          const { sense_version: version, apis } = req.query;
          if (!apis) {
            throw _boom2.default.badRequest('"apis" is a required param.');
          }

          return (0, _server.resolveApi)(version, apis.split(','), h);
        }
      });
    },

    uiExports: {
      apps: apps,
      hacks: ['plugins/console/hacks/register'],
      devTools: ['plugins/console/console'],
      styleSheetPaths: (0, _path.resolve)(__dirname, 'public/index.scss'),

      injectDefaultVars(server) {
        return {
          elasticsearchUrl: _url2.default.format(Object.assign(_url2.default.parse((0, _lodash.head)(server.config().get('elasticsearch.hosts'))), { auth: false }))
        };
      },

      noParse: [(0, _path.join)(modules, 'ace' + _path.sep), (0, _path.join)(modules, 'moment_src/moment' + _path.sep), (0, _path.join)(src, 'sense_editor/mode/worker.js')]
    }
  });
};

var _boom = require('boom');

var _boom2 = _interopRequireDefault(_boom);

var _path = require('path');

var _url = require('url');

var _url2 = _interopRequireDefault(_url);

var _lodash = require('lodash');

var _server = require('./api_server/server');

var _spec = require('./api_server/spec');

var _set_headers = require('../elasticsearch/lib/set_headers');

var _set_headers2 = _interopRequireDefault(_set_headers);

var _server2 = require('./server');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

module.exports = exports['default'];