'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.extendConfigService = extendConfigService;
exports.disableConfigExtension = disableConfigExtension;

var _settings = require('./settings');

var _schema = require('./schema');

/**
 *  Extend a config service with the schema and settings for a
 *  plugin spec and optionally call logDeprecation with warning
 *  messages about deprecated settings that are used
 *  @param  {PluginSpec} spec
 *  @param  {Server.Config} config
 *  @param  {Object} rootSettings
 *  @param  {Function} [logDeprecation]
 *  @return {Promise<undefined>}
 */
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

async function extendConfigService(spec, config, rootSettings, logDeprecation) {
  const settings = await (0, _settings.getSettings)(spec, rootSettings, logDeprecation);
  const schema = await (0, _schema.getSchema)(spec);
  config.extendSchema(schema, settings, spec.getConfigPrefix());
}

/**
 *  Disable the schema and settings applied to a config service for
 *  a plugin spec
 *  @param  {PluginSpec} spec
 *  @param  {Server.Config} config
 *  @return {undefined}
 */
function disableConfigExtension(spec, config) {
  const prefix = spec.getConfigPrefix();
  config.removeSchema(prefix);
  config.extendSchema((0, _schema.getStubSchema)(), { enabled: false }, prefix);
}