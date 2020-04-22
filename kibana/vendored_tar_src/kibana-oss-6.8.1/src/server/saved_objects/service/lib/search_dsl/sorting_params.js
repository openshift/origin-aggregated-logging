'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getSortingParams = getSortingParams;

var _boom = require('boom');

var _boom2 = _interopRequireDefault(_boom);

var _mappings = require('../../../../mappings');

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

function getSortingParams(mappings, type, sortField, sortOrder) {
  if (!sortField) {
    return {};
  }

  let typeField = type;

  if (Array.isArray(type)) {
    if (type.length === 1) {
      typeField = type[0];
    } else {
      const rootField = (0, _mappings.getProperty)(mappings, sortField);
      if (!rootField) {
        throw _boom2.default.badRequest(`Unable to sort multiple types by field ${sortField}, not a root property`);
      }

      return {
        sort: [{
          [sortField]: {
            order: sortOrder,
            unmapped_type: rootField.type
          }
        }]
      };
    }
  }

  const key = `${typeField}.${sortField}`;
  const field = (0, _mappings.getProperty)(mappings, key);
  if (!field) {
    throw _boom2.default.badRequest(`Unknown sort field ${sortField}`);
  }

  return {
    sort: [{
      [key]: {
        order: sortOrder,
        unmapped_type: field.type
      }
    }]
  };
}