'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = carry;

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _i18n = require('@kbn/i18n');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// Upsampling of non-cumulative sets
// Good: average, min, max
// Bad: sum, count

// Don't use this to down sample, it simply won't do the right thing.
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

function carry(dataTuples, targetTuples) {

  if (dataTuples.length > targetTuples.length) {
    throw new Error(_i18n.i18n.translate('timelion.fitFunctions.carry.downSampleErrorMessage', {
      defaultMessage: `Don't use the 'carry' fit method to down sample, use 'scale' or 'average'`,
      description: '"carry", "scale" and "average" are parameter values that must not be translated.'
    }));
  }

  let currentCarry = dataTuples[0][1];
  return _lodash2.default.map(targetTuples, function (bucket) {
    const targetTime = bucket[0];
    const dataTime = dataTuples[0][0];

    if (dataTuples[0] && targetTime >= dataTime) {
      currentCarry = dataTuples[0][1];
      if (dataTuples.length > 1) {
        dataTuples.shift();
      }
    }

    return [bucket[0], currentCarry];
  });
}
module.exports = exports['default'];