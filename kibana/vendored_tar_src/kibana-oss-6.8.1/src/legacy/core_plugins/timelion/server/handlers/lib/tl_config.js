'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = tlConfigFn;

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _build_target = require('../../lib/build_target.js');

var _build_target2 = _interopRequireDefault(_build_target);

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

function tlConfigFn(setup) {
  let targetSeries;

  let tlConfig = {
    getTargetSeries: function () {
      return _lodash2.default.map(targetSeries, function (bucket) {
        // eslint-disable-line no-use-before-define
        return [bucket, null];
      });
    },
    setTargetSeries: function () {
      targetSeries = (0, _build_target2.default)(this);
    },
    writeTargetSeries: function (series) {
      targetSeries = _lodash2.default.map(series, function (p) {
        return p[0];
      });
    }
  };

  tlConfig = _lodash2.default.extend(tlConfig, setup);
  return tlConfig;
}
module.exports = exports['default'];