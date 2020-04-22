'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _color = require('./color');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const log = _lodash2.default.restParam(function (color, label, rest1) {
  console.log.apply(console, [color(` ${_lodash2.default.trim(label)} `)].concat(rest1));
}); /*
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

class Log {
  constructor(quiet, silent) {
    this.good = quiet || silent ? _lodash2.default.noop : _lodash2.default.partial(log, _color.green);
    this.warn = quiet || silent ? _lodash2.default.noop : _lodash2.default.partial(log, _color.yellow);
    this.bad = silent ? _lodash2.default.noop : _lodash2.default.partial(log, _color.red);
  }
}
exports.default = Log;
module.exports = exports['default'];