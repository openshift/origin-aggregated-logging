'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.readKeystore = readKeystore;

var _path = require('path');

var _path2 = _interopRequireDefault(_path);

var _lodash = require('lodash');

var _keystore = require('../../server/keystore');

var _path3 = require('../../server/path');

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

function readKeystore(dataPath = (0, _path3.getData)()) {
  const keystore = new _keystore.Keystore(_path2.default.join(dataPath, 'kibana.keystore'));
  keystore.load();

  const keys = Object.keys(keystore.data);
  const data = {};

  keys.forEach(key => {
    (0, _lodash.set)(data, key, keystore.data[key]);
  });

  return data;
}