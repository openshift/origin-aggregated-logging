'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

exports.default = function () {
  function flattenWith(dot, nestedObj, flattenArrays) {
    const stack = []; // track key stack
    const flatObj = {};
    (function flattenObj(obj) {
      _lodash2.default.keys(obj).forEach(function (key) {
        stack.push(key);
        if (!flattenArrays && Array.isArray(obj[key])) flatObj[stack.join(dot)] = obj[key];else if (_lodash2.default.isObject(obj[key])) flattenObj(obj[key]);else flatObj[stack.join(dot)] = obj[key];
        stack.pop();
      });
    })(nestedObj);
    return flatObj;
  }

  const timelionDefaults = flattenWith('.', _timelion2.default);
  return _lodash2.default.reduce(timelionDefaults, (result, value, key) => {
    result['timelion:' + key] = value;
    return result;
  }, {});
};

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _timelion = require('../../timelion.json');

var _timelion2 = _interopRequireDefault(_timelion);

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