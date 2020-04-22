'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getColumnData = getColumnData;

var _get_request_params = require('./get_request_params');

var _get_request_params2 = _interopRequireDefault(_get_request_params);

var _handle_response_body = require('./handle_response_body');

var _handle_response_body2 = _interopRequireDefault(_handle_response_body);

var _handle_error_response = require('../handle_error_response');

var _handle_error_response2 = _interopRequireDefault(_handle_error_response);

var _get_last_value = require('../../../../common/get_last_value');

var _get_last_value2 = _interopRequireDefault(_get_last_value);

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _regression = require('regression');

var _regression2 = _interopRequireDefault(_regression);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/*
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

function getColumnData(req, panel, entities, client) {
  const elasticsearch = _lodash2.default.get(req, 'server.plugins.elasticsearch');
  if (elasticsearch) {
    const { callWithRequest } = elasticsearch.getCluster('data');
    if (!client) {
      client = callWithRequest.bind(null, req);
    }
  }
  const params = {
    rest_total_hits_as_int: true,
    body: (0, _get_request_params2.default)(req, panel, entities)
  };
  return client('msearch', params).then(resp => {
    const handler = (0, _handle_response_body2.default)(panel);
    return entities.map((entity, index) => {
      entity.data = {};
      handler(resp.responses[index]).forEach(row => {
        const linearRegression = (0, _regression2.default)('linear', row.data);
        entity.data[row.id] = {
          last: (0, _get_last_value2.default)(row.data),
          slope: linearRegression.equation[0],
          yIntercept: linearRegression.equation[1],
          label: row.label
        };
      });
      return entity;
    });
  }).catch((0, _handle_error_response2.default)(panel));
}