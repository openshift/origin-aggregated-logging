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

exports.registerScrollForExportRoute = registerScrollForExportRoute;
exports.registerScrollForCountRoute = registerScrollForCountRoute;

var _joi = require('joi');

var _joi2 = _interopRequireDefault(_joi);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

async function findAll(savedObjectsClient, findOptions, page = 1, allObjects = []) {
  const objects = await savedObjectsClient.find(_extends({}, findOptions, {
    page
  }));

  allObjects.push(...objects.saved_objects);
  if (allObjects.length < objects.total) {
    return findAll(savedObjectsClient, findOptions, page + 1, allObjects);
  }

  return allObjects;
}

function registerScrollForExportRoute(server) {
  server.route({
    path: '/api/kibana/management/saved_objects/scroll/export',
    method: ['POST'],
    config: {
      validate: {
        payload: _joi2.default.object().keys({
          typesToInclude: _joi2.default.array().items(_joi2.default.string()).required()
        }).required()
      }
    },

    handler: async req => {
      const savedObjectsClient = req.getSavedObjectsClient();
      const objects = await findAll(savedObjectsClient, {
        perPage: 1000,
        type: req.payload.typesToInclude
      });

      return objects.map(hit => {
        const type = hit.type;
        return {
          _id: hit.id,
          _type: type,
          _source: hit.attributes,
          _meta: {
            savedObjectVersion: 2
          },
          _migrationVersion: hit.migrationVersion
        };
      });
    }
  });
}

function registerScrollForCountRoute(server) {
  server.route({
    path: '/api/kibana/management/saved_objects/scroll/counts',
    method: ['POST'],
    config: {
      validate: {
        payload: _joi2.default.object().keys({
          typesToInclude: _joi2.default.array().items(_joi2.default.string()).required(),
          searchString: _joi2.default.string()
        }).required()
      }
    },

    handler: async req => {
      const savedObjectsClient = req.getSavedObjectsClient();
      const findOptions = {
        type: req.payload.typesToInclude,
        perPage: 1000
      };

      if (req.payload.searchString) {
        findOptions.search = `${req.payload.searchString}*`;
        findOptions.searchFields = ['title'];
      }

      const objects = await findAll(savedObjectsClient, findOptions);
      const counts = objects.reduce((accum, result) => {
        const type = result.type;
        accum[type] = accum[type] || 0;
        accum[type]++;
        return accum;
      }, {});

      for (const type of req.payload.typesToInclude) {
        if (!counts[type]) {
          counts[type] = 0;
        }
      }

      return counts;
    }
  });
}