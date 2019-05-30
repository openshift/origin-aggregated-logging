'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = handleResponseBody;

var _build_processor_function = require('../build_processor_function');

var _build_processor_function2 = _interopRequireDefault(_build_processor_function);

var _series = require('../response_processors/series');

var _series2 = _interopRequireDefault(_series);

var _lodash = require('lodash');

var _i18n = require('@kbn/i18n');

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

function handleResponseBody(panel) {
  return resp => {
    if (resp.error) {
      const err = new Error(resp.error.type);
      err.response = JSON.stringify(resp);
      throw err;
    }
    const aggregations = (0, _lodash.get)(resp, 'aggregations');
    if (!aggregations) {
      const message = _i18n.i18n.translate('tsvb.series.missingAggregationKeyErrorMessage', {
        defaultMessage: 'The aggregations key is missing from the response, check your permissions for this request.'
      });
      throw Error(message);
    }
    const keys = Object.keys(aggregations);
    if (keys.length !== 1) {
      throw Error(_i18n.i18n.translate('tsvb.series.shouldOneSeriesPerRequestErrorMessage', {
        defaultMessage: 'There should only be one series per request.'
      }));
    }
    const seriesId = keys[0];
    const series = panel.series.find(s => s.id === seriesId);
    const processor = (0, _build_processor_function2.default)(_series2.default, resp, panel, series);
    return processor([]);
  };
}
module.exports = exports['default'];