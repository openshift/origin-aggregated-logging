'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

exports.default = function (directory) {

  function getTuple(directory, name) {
    return [name, require('../' + directory + '/' + name)]; // eslint-disable-line import/no-dynamic-require
  }

  // Get a list of all files and use the filename as the object key
  const files = _lodash2.default.map(_glob2.default.sync(_path2.default.resolve(__dirname, '../' + directory + '/*.js')), function (file) {
    const name = file.substring(file.lastIndexOf('/') + 1, file.lastIndexOf('.'));
    return getTuple(directory, name);
  });

  // Get a list of all directories with an index.js, use the directory name as the key in the object
  const directories = _lodash2.default.chain(_glob2.default.sync(_path2.default.resolve(__dirname, '../' + directory + '/*/index.js'))).filter(function (file) {
    return file.match(/__test__/) == null;
  }).map(function (file) {
    const parts = file.split('/');
    const name = parts[parts.length - 2];
    return getTuple(directory, name);
  }).value();

  const functions = _lodash2.default.zipObject(files.concat(directories));

  _lodash2.default.each(functions, function (func) {
    _lodash2.default.assign(functions, (0, _process_function_definition2.default)(func));
  });

  return functions;
};

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _glob = require('glob');

var _glob2 = _interopRequireDefault(_glob);

var _path = require('path');

var _path2 = _interopRequireDefault(_path);

var _process_function_definition = require('./process_function_definition');

var _process_function_definition2 = _interopRequireDefault(_process_function_definition);

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