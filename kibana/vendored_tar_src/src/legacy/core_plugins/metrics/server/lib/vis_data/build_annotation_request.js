'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = buildAnnotationRequest;

var _build_processor_function = require('./build_processor_function');

var _build_processor_function2 = _interopRequireDefault(_build_processor_function);

var _annotations = require('./request_processors/annotations');

var _annotations2 = _interopRequireDefault(_annotations);

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

function buildAnnotationRequest(req, panel, annotation, esQueryConfig, indexPattern) {
  const processor = (0, _build_processor_function2.default)(_annotations2.default, req, panel, annotation, esQueryConfig, indexPattern);
  const doc = processor({});
  return doc;
}
module.exports = exports['default'];