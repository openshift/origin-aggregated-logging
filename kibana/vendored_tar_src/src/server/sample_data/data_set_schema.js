'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.sampleDataSchema = undefined;

var _joi = require('joi');

var _joi2 = _interopRequireDefault(_joi);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const dataIndexSchema = _joi2.default.object({
  id: _joi2.default.string().regex(/^[a-zA-Z0-9-]+$/).required(),

  // path to newline delimented JSON file containing data relative to KIBANA_HOME
  dataPath: _joi2.default.string().required(),

  // Object defining Elasticsearch field mappings (contents of index.mappings.type.properties)
  fields: _joi2.default.object().required(),

  // times fields that will be updated relative to now when data is installed
  timeFields: _joi2.default.array().items(_joi2.default.string()).required(),

  // Reference to now in your test data set.
  // When data is installed, timestamps are converted to the present time.
  // The distance between a timestamp and currentTimeMarker is preserved but the date and time will change.
  // For example:
  //   sample data set:    timestamp: 2018-01-01T00:00:00Z, currentTimeMarker: 2018-01-01T12:00:00Z
  //   installed data set: timestamp: 2018-04-18T20:33:14Z, currentTimeMarker: 2018-04-19T08:33:14Z
  currentTimeMarker: _joi2.default.string().isoDate().required(),

  // Set to true to move timestamp to current week, preserving day of week and time of day
  // Relative distance from timestamp to currentTimeMarker will not remain the same
  preserveDayOfWeekTimeOfDay: _joi2.default.boolean().default(false)
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

const sampleDataSchema = exports.sampleDataSchema = {
  id: _joi2.default.string().regex(/^[a-zA-Z0-9-]+$/).required(),
  name: _joi2.default.string().required(),
  description: _joi2.default.string().required(),
  previewImagePath: _joi2.default.string().required(),

  // saved object id of main dashboard for sample data set
  overviewDashboard: _joi2.default.string().required(),

  // saved object id of default index-pattern for sample data set
  defaultIndex: _joi2.default.string().required(),

  // Kibana saved objects (index patter, visualizations, dashboard, ...)
  // Should provide a nice demo of Kibana's functionality with the sample data set
  savedObjects: _joi2.default.array().items(_joi2.default.object()).required(),
  dataIndices: _joi2.default.array().items(dataIndexSchema).required()
};