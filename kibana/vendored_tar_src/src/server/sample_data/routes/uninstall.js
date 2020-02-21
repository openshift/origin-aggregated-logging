'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createUninstallRoute = undefined;

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _joi = require('joi');

var _joi2 = _interopRequireDefault(_joi);

var _create_index_name = require('./lib/create_index_name');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const createUninstallRoute = exports.createUninstallRoute = () => ({
  path: '/api/sample_data/{id}',
  method: 'DELETE',
  config: {
    validate: {
      params: _joi2.default.object().keys({
        id: _joi2.default.string().required()
      }).required()
    },
    handler: async (request, h) => {
      const server = request.server;
      const sampleDataset = server.getSampleDatasets().find(({ id }) => {
        return id === request.params.id;
      });

      if (!sampleDataset) {
        return h.response().code(404);
      }

      const { callWithRequest } = server.plugins.elasticsearch.getCluster('data');

      for (let i = 0; i < sampleDataset.dataIndices.length; i++) {
        const dataIndexConfig = sampleDataset.dataIndices[i];
        const index = (0, _create_index_name.createIndexName)(sampleDataset.id, dataIndexConfig.id);

        try {
          await callWithRequest(request, 'indices.delete', { index: index });
        } catch (err) {
          return h.response(`Unable to delete sample data index "${index}", error: ${err.message}`).code(err.status);
        }
      }

      const deletePromises = sampleDataset.savedObjects.map(savedObjectJson => {
        return request.getSavedObjectsClient().delete(savedObjectJson.type, savedObjectJson.id);
      });
      try {
        await Promise.all(deletePromises);
      } catch (err) {
        // ignore 404s since users could have deleted some of the saved objects via the UI
        if (_lodash2.default.get(err, 'output.statusCode') !== 404) {
          return h.response(`Unable to delete sample dataset saved objects, error: ${err.message}`).code(403);
        }
      }

      return {};
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