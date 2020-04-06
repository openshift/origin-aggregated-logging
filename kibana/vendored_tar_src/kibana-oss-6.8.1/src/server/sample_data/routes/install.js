'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createInstallRoute = undefined;

var _boom = require('boom');

var _boom2 = _interopRequireDefault(_boom);

var _joi = require('joi');

var _joi2 = _interopRequireDefault(_joi);

var _load_data = require('./lib/load_data');

var _create_index_name = require('./lib/create_index_name');

var _translate_timestamp = require('./lib/translate_timestamp');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function insertDataIntoIndex(dataIndexConfig, index, nowReference, request, server, callWithRequest) {
  const bulkInsert = async docs => {
    function updateTimestamps(doc) {
      dataIndexConfig.timeFields.forEach(timeFieldName => {
        if (doc[timeFieldName]) {
          doc[timeFieldName] = dataIndexConfig.preserveDayOfWeekTimeOfDay ? (0, _translate_timestamp.translateTimeRelativeToWeek)(doc[timeFieldName], dataIndexConfig.currentTimeMarker, nowReference) : (0, _translate_timestamp.translateTimeRelativeToDifference)(doc[timeFieldName], dataIndexConfig.currentTimeMarker, nowReference);
        }
      });
      return doc;
    }

    const insertCmd = {
      index: {
        _index: index,
        _type: '_doc'
      }
    };

    const bulk = [];
    docs.forEach(doc => {
      bulk.push(insertCmd);
      bulk.push(updateTimestamps(doc));
    });
    const resp = await callWithRequest(request, 'bulk', { body: bulk });
    if (resp.errors) {
      server.log(['warning'], `sample_data install errors while bulk inserting. Elasticsearch response: ${JSON.stringify(resp, null, '')}`);
      return Promise.reject(new Error(`Unable to load sample data into index "${index}", see kibana logs for details`));
    }
  };

  return (0, _load_data.loadData)(dataIndexConfig.dataPath, bulkInsert);
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

const createInstallRoute = exports.createInstallRoute = () => ({
  path: '/api/sample_data/{id}',
  method: 'POST',
  config: {
    validate: {
      query: _joi2.default.object().keys({
        now: _joi2.default.date().iso()
      }),
      params: _joi2.default.object().keys({
        id: _joi2.default.string().required()
      }).required()
    },
    handler: async (request, h) => {
      const server = request.server;
      const sampleDataset = server.getSampleDatasets().find(sampleDataset => {
        return sampleDataset.id === request.params.id;
      });
      if (!sampleDataset) {
        return h.response().code(404);
      }

      const { callWithRequest } = server.plugins.elasticsearch.getCluster('data');

      const now = request.query.now ? request.query.now : new Date();
      const nowReference = (0, _translate_timestamp.dateToIso8601IgnoringTime)(now);

      const counts = {};
      for (let i = 0; i < sampleDataset.dataIndices.length; i++) {
        const dataIndexConfig = sampleDataset.dataIndices[i];
        const index = (0, _create_index_name.createIndexName)(sampleDataset.id, dataIndexConfig.id);

        // clean up any old installation of dataset
        try {
          await callWithRequest(request, 'indices.delete', { index: index });
        } catch (err) {
          // ignore delete errors
        }

        try {
          const createIndexParams = {
            index: index,
            body: {
              settings: {
                index: {
                  number_of_shards: 1,
                  auto_expand_replicas: '0-1'
                }
              },
              mappings: {
                _doc: {
                  properties: dataIndexConfig.fields
                }
              }
            },
            include_type_name: true
          };
          await callWithRequest(request, 'indices.create', createIndexParams);
        } catch (err) {
          const errMsg = `Unable to create sample data index "${index}", error: ${err.message}`;
          server.log(['warning'], errMsg);
          return h.response(errMsg).code(err.status);
        }

        try {
          const count = await insertDataIntoIndex(dataIndexConfig, index, nowReference, request, server, callWithRequest);
          counts[index] = count;
        } catch (err) {
          server.log(['warning'], `sample_data install errors while loading data. Error: ${err}`);
          return h.response(err.message).code(500);
        }
      }

      let createResults;
      try {
        createResults = await request.getSavedObjectsClient().bulkCreate(sampleDataset.savedObjects, { overwrite: true });
      } catch (err) {
        server.log(['warning'], `bulkCreate failed, error: ${err.message}`);
        return _boom2.default.badImplementation(`Unable to load kibana saved objects, see kibana logs for details`);
      }
      const errors = createResults.saved_objects.filter(savedObjectCreateResult => {
        return savedObjectCreateResult.hasOwnProperty('error');
      });
      if (errors.length > 0) {
        server.log(['warning'], `sample_data install errors while loading saved objects. Errors: ${errors.join(',')}`);
        return h.response(`Unable to load kibana saved objects, see kibana logs for details`).code(403);
      }

      return h.response({ elasticsearchIndicesCreated: counts, kibanaSavedObjectsLoaded: sampleDataset.savedObjects.length });
    }
  }
});