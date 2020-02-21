'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createCreateRoute = undefined;

var _joi = require('joi');

var _joi2 = _interopRequireDefault(_joi);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const createCreateRoute = exports.createCreateRoute = prereqs => {
  return {
    path: '/api/saved_objects/{type}/{id?}',
    method: 'POST',
    options: {
      pre: [prereqs.getSavedObjectsClient],
      validate: {
        query: _joi2.default.object().keys({
          overwrite: _joi2.default.boolean().default(false)
        }).default(),
        params: _joi2.default.object().keys({
          type: _joi2.default.string().required(),
          id: _joi2.default.string()
        }).required(),
        payload: _joi2.default.object({
          attributes: _joi2.default.object().required(),
          migrationVersion: _joi2.default.object().optional()
        }).required()
      },
      handler(request) {
        const { savedObjectsClient } = request.pre;
        const { type, id } = request.params;
        const { overwrite } = request.query;
        const { migrationVersion } = request.payload;
        const options = { id, overwrite, migrationVersion };

        return savedObjectsClient.create(type, request.payload.attributes, options);
      }
    }
  };
}; /*
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