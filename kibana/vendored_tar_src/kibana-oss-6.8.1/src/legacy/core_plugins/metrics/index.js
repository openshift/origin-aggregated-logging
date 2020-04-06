'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

exports.default = function (kibana) {
  return new kibana.Plugin({
    require: ['kibana', 'elasticsearch'],

    uiExports: {
      visTypes: ['plugins/metrics/kbn_vis_types'],
      styleSheetPaths: (0, _path.resolve)(__dirname, 'public/index.scss')
    },

    config(Joi) {
      return Joi.object({
        enabled: Joi.boolean().default(true),
        chartResolution: Joi.number().default(150),
        minimumBucketSize: Joi.number().default(10)
      }).default();
    },

    init(server) {
      (0, _fields2.default)(server);
      (0, _vis2.default)(server);
    }

  });
};

var _path = require('path');

var _fields = require('./server/routes/fields');

var _fields2 = _interopRequireDefault(_fields);

var _vis = require('./server/routes/vis');

var _vis2 = _interopRequireDefault(_vis);

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

module.exports = exports['default'];