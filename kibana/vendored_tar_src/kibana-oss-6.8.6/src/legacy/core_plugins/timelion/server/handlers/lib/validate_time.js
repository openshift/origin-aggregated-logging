'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = validateTime;

var _i18n = require('@kbn/i18n');

var _date_math = require('../../lib/date_math.js');

var _date_math2 = _interopRequireDefault(_date_math);

var _to_milliseconds = require('../../lib/to_milliseconds.js');

var _to_milliseconds2 = _interopRequireDefault(_to_milliseconds);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function validateTime(time, tlConfig) {
  const span = (0, _date_math2.default)(time.to, true) - (0, _date_math2.default)(time.from);
  const interval = (0, _to_milliseconds2.default)(time.interval);
  const bucketCount = span / interval;
  const maxBuckets = tlConfig.settings['timelion:max_buckets'];
  if (bucketCount > maxBuckets) {
    throw new Error(_i18n.i18n.translate('timelion.serverSideErrors.bucketsOverflowErrorMessage', {
      defaultMessage: 'Max buckets exceeded: {bucketCount} of {maxBuckets} allowed. ' + 'Choose a larger interval or a shorter time span',
      values: {
        bucketCount: Math.round(bucketCount),
        maxBuckets
      }
    }));
  }
  return true;
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