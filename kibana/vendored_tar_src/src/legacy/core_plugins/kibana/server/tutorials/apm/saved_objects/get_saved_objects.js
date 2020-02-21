'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getSavedObjects = getSavedObjects;

var _index_pattern = require('./index_pattern.json');

var _index_pattern2 = _interopRequireDefault(_index_pattern);

var _saved_objects = require('./saved_objects.json');

var _saved_objects2 = _interopRequireDefault(_saved_objects);

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

function getIndexPatternWithTitle(indexPatternTitle) {
  _index_pattern2.default.attributes.title = indexPatternTitle;
  return _index_pattern2.default;
}

function getSavedObjects(indexPatternTitle) {
  return [getIndexPatternWithTitle(indexPatternTitle), ..._saved_objects2.default];
}