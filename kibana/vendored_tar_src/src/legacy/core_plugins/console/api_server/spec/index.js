'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; }; /*
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

exports.getSpec = getSpec;
exports.addExtensionSpecFilePath = addExtensionSpecFilePath;

var _glob = require('glob');

var _glob2 = _interopRequireDefault(_glob);

var _path = require('path');

var _fs = require('fs');

var _lodash = require('lodash');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const extensionSpecFilePaths = [];
function _getSpec(dirname = __dirname) {
  const generatedFiles = _glob2.default.sync((0, _path.join)(dirname, 'generated', '*.json'));
  const overrideFiles = _glob2.default.sync((0, _path.join)(dirname, 'overrides', '*.json'));

  return generatedFiles.reduce((acc, file) => {
    const overrideFile = overrideFiles.find(f => (0, _path.basename)(f) === (0, _path.basename)(file));
    const loadedSpec = JSON.parse((0, _fs.readFileSync)(file, 'utf8'));
    if (overrideFile) {
      (0, _lodash.merge)(loadedSpec, JSON.parse((0, _fs.readFileSync)(overrideFile, 'utf8')));
    }
    const spec = {};
    Object.entries(loadedSpec).forEach(([key, value]) => {
      if (acc[key]) {
        // add time to remove key collision
        spec[`${key}${Date.now()}`] = value;
      } else {
        spec[key] = value;
      }
    });

    return _extends({}, acc, spec);
  }, {});
}
function getSpec() {
  const result = _getSpec();
  extensionSpecFilePaths.forEach(extensionSpecFilePath => {
    (0, _lodash.merge)(result, _getSpec(extensionSpecFilePath));
  });
  return result;
}

function addExtensionSpecFilePath(extensionSpecFilePath) {
  extensionSpecFilePaths.push(extensionSpecFilePath);
}