'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _calculate_auto = require('./calculate_auto');

var _calculate_auto2 = _interopRequireDefault(_calculate_auto);

var _moment = require('moment');

var _moment2 = _interopRequireDefault(_moment);

var _unit_to_seconds = require('./unit_to_seconds');

var _unit_to_seconds2 = _interopRequireDefault(_unit_to_seconds);

var _interval_regexp = require('../../../../common/interval_regexp');

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

exports.default = (req, interval) => {
  const from = _moment2.default.utc(req.payload.timerange.min);
  const to = _moment2.default.utc(req.payload.timerange.max);
  const duration = _moment2.default.duration(to.valueOf() - from.valueOf(), 'ms');
  let bucketSize = _calculate_auto2.default.near(100, duration).asSeconds();
  if (bucketSize < 1) bucketSize = 1; // don't go too small
  let intervalString = `${bucketSize}s`;

  const gteAutoMatch = interval && interval.match(_interval_regexp.GTE_INTERVAL_RE);
  if (gteAutoMatch) {
    const intervalStringMatch = gteAutoMatch[1].match(_interval_regexp.INTERVAL_STRING_RE);
    const gteBucketSize = Number(intervalStringMatch[1]) * (0, _unit_to_seconds2.default)(intervalStringMatch[2]);
    if (gteBucketSize >= bucketSize) {
      return {
        bucketSize: gteBucketSize,
        intervalString: gteAutoMatch[1]
      };
    }
  }

  const matches = interval && interval.match(_interval_regexp.INTERVAL_STRING_RE);
  if (matches) {
    bucketSize = Number(matches[1]) * (0, _unit_to_seconds2.default)(matches[2]);
    intervalString = interval;
  }

  return { bucketSize, intervalString };
};

module.exports = exports['default'];