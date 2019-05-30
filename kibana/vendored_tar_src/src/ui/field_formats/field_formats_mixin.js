'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.fieldFormatsMixin = fieldFormatsMixin;

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _field_formats_service = require('./field_formats_service');

var _field_format = require('./field_format');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function fieldFormatsMixin(kbnServer, server) {
  const fieldFormatClasses = [];

  // for use outside of the request context, for special cases
  server.decorate('server', 'fieldFormatServiceFactory', async function (uiSettings) {
    const uiConfigs = await uiSettings.getAll();
    const uiSettingDefaults = await uiSettings.getDefaults();
    Object.keys(uiSettingDefaults).forEach(key => {
      if (_lodash2.default.has(uiConfigs, key) && uiSettingDefaults[key].type === 'json') {
        uiConfigs[key] = JSON.parse(uiConfigs[key]);
      }
    });
    const getConfig = key => uiConfigs[key];
    return new _field_formats_service.FieldFormatsService(fieldFormatClasses, getConfig);
  });

  server.decorate('server', 'registerFieldFormat', createFormat => {
    fieldFormatClasses.push(createFormat(_field_format.FieldFormat));
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