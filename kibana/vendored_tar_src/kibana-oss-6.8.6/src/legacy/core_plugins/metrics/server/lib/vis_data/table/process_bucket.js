'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = processBucket;

var _build_processor_function = require('../build_processor_function');

var _build_processor_function2 = _interopRequireDefault(_build_processor_function);

var _table = require('../response_processors/table');

var _table2 = _interopRequireDefault(_table);

var _get_last_value = require('../../../../common/get_last_value');

var _get_last_value2 = _interopRequireDefault(_get_last_value);

var _regression = require('regression');

var _regression2 = _interopRequireDefault(_regression);

var _lodash = require('lodash');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function processBucket(panel) {
  return bucket => {
    const series = panel.series.map(series => {
      const processor = (0, _build_processor_function2.default)(_table2.default, bucket, panel, series);
      const result = (0, _lodash.first)(processor([]));
      if (!result) return null;
      const data = (0, _lodash.get)(result, 'data', []);
      const linearRegression = _regression2.default.linear(data);
      result.last = (0, _get_last_value2.default)(data);
      result.slope = linearRegression.equation[0];
      return result;
    });
    return { key: bucket.key, series };
  };
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

module.exports = exports['default'];