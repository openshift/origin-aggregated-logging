'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createFieldsForTimePatternRoute = undefined;

var _joi = require('joi');

var _joi2 = _interopRequireDefault(_joi);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const createFieldsForTimePatternRoute = exports.createFieldsForTimePatternRoute = pre => ({
  path: '/api/index_patterns/_fields_for_time_pattern',
  method: 'GET',
  config: {
    pre: [pre.getIndexPatternsService],
    validate: {
      query: _joi2.default.object().keys({
        pattern: _joi2.default.string().required(),
        look_back: _joi2.default.number().min(1).required(),
        meta_fields: _joi2.default.array().items(_joi2.default.string()).default([])
      }).default()
    },
    async handler(req) {
      const { indexPatterns } = req.pre;
      const {
        pattern,
        interval,
        look_back: lookBack,
        meta_fields: metaFields
      } = req.query;

      const fields = await indexPatterns.getFieldsForTimePattern({
        pattern,
        interval,
        lookBack,
        metaFields
      });

      return { fields };
    }
  }
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