'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createProxy = createProxy;

var _joi = require('joi');

var _joi2 = _interopRequireDefault(_joi);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function createProxy(server) {
  const { callWithRequest } = server.plugins.elasticsearch.getCluster('data');

  server.route({
    method: 'POST',
    path: '/elasticsearch/_msearch',
    config: {
      payload: {
        parse: 'gunzip'
      }
    },
    async handler(req, h) {
      const { query, payload } = req;
      return callWithRequest(req, 'transport.request', {
        path: '/_msearch',
        method: 'POST',
        query,
        body: payload.toString('utf8')
      }).finally(r => h.response(r));
    }
  });

  server.route({
    method: 'POST',
    path: '/elasticsearch/{index}/_search',
    config: {
      validate: {
        params: _joi2.default.object().keys({
          index: _joi2.default.string().required()
        })
      }
    },
    handler(req, h) {
      const { query, payload: body } = req;
      return callWithRequest(req, 'transport.request', {
        path: `/${encodeURIComponent(req.params.index)}/_search`,
        method: 'POST',
        query,
        body
      }).finally(r => h.response(r));
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