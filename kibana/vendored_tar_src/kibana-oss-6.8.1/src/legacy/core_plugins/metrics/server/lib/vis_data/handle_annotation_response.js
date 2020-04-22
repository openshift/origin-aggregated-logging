'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = handleAnnotationResponse;

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function handleAnnotationResponse(resp, annotation) {
  return _lodash2.default.get(resp, `aggregations.${annotation.id}.buckets`, []).filter(bucket => bucket.hits.hits.total).map(bucket => {
    return {
      key: bucket.key,
      docs: bucket.hits.hits.hits.map(doc => doc._source)
    };
  });
} /*
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

module.exports = exports['default'];