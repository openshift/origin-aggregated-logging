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


exports.getTableData = getTableData;

var _lodash = require('lodash');

var _build_request_body = require('./table/build_request_body');

var _build_request_body2 = _interopRequireDefault(_build_request_body);

var _handle_error_response = require('./handle_error_response');

var _handle_error_response2 = _interopRequireDefault(_handle_error_response);

var _process_bucket = require('./table/process_bucket');

var _process_bucket2 = _interopRequireDefault(_process_bucket);

var _get_index_pattern = require('./helpers/get_index_pattern');

var _get_es_query_uisettings = require('./helpers/get_es_query_uisettings');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

async function getTableData(req, panel) {
  const { callWithRequest } = req.server.plugins.elasticsearch.getCluster('data');
  const includeFrozen = await req.getUiSettingsService().get('search:includeFrozen');

  const esQueryConfig = await (0, _get_es_query_uisettings.getEsQueryConfig)(req);
  const indexPattern = panel.index_pattern;
  const { indexPatternObject, indexPatternString } = await (0, _get_index_pattern.getIndexPatternObject)(req, indexPattern);

  const params = {
    index: indexPatternString,
    ignore_throttled: !includeFrozen,
    body: (0, _build_request_body2.default)(req, panel, esQueryConfig, indexPatternObject)
  };
  try {
    const resp = await callWithRequest(req, 'search', params);
    const buckets = (0, _lodash.get)(resp, 'aggregations.pivot.buckets', []);
    return { type: 'table', series: buckets.map((0, _process_bucket2.default)(panel)) };
  } catch (err) {
    if (err.body) {
      err.response = err.body;
      return _extends({ type: 'table' }, (0, _handle_error_response2.default)(panel)(err));
    }
  }
}