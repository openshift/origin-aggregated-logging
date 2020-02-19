'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.importApi = importApi;

var _boom = require('boom');

var _boom2 = _interopRequireDefault(_boom);

var _joi = require('joi');

var _joi2 = _interopRequireDefault(_joi);

var _import_dashboards = require('../../../lib/import/import_dashboards');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function importApi(server) {
  server.route({
    path: '/api/kibana/dashboards/import',
    method: ['POST'],
    config: {
      validate: {
        payload: _joi2.default.object().keys({
          objects: _joi2.default.array(),
          version: _joi2.default.string()
        }),
        query: _joi2.default.object().keys({
          force: _joi2.default.boolean().default(false),
          exclude: [_joi2.default.string(), _joi2.default.array().items(_joi2.default.string())]
        })
      },
      tags: ['api']
    },

    handler: async req => {
      try {
        return await (0, _import_dashboards.importDashboards)(req);
      } catch (err) {
        throw _boom2.default.boomify(err, { statusCode: 400 });
      }
    }
  });
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