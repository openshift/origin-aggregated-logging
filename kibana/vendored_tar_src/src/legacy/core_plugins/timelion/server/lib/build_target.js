'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

exports.default = function (tlConfig) {
  const min = (0, _moment2.default)(tlConfig.time.from);
  const max = (0, _moment2.default)(tlConfig.time.to);

  const intervalParts = (0, _split_interval2.default)(tlConfig.time.interval);

  let current = min.startOf(intervalParts.unit);

  const targetSeries = [];

  while (current.valueOf() < max.valueOf()) {
    targetSeries.push(current.valueOf());
    current = current.add(intervalParts.count, intervalParts.unit);
  }

  return targetSeries;
};

var _moment = require('moment');

var _moment2 = _interopRequireDefault(_moment);

var _split_interval = require('./split_interval.js');

var _split_interval2 = _interopRequireDefault(_split_interval);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

module.exports = exports['default']; /*
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