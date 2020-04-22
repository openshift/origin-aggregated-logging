'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _lodash = require('lodash');

var _transform_deprecations = require('./transform_deprecations');

var _utils = require('../../utils');

var _deprecation = require('../../deprecation');

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

const getFlattenedKeys = object => Object.keys((0, _utils.getFlattenedObject)(object));

async function getUnusedConfigKeys(coreHandledConfigPaths, plugins, disabledPluginSpecs, rawSettings, configValues) {
  // transform deprecated core settings
  const settings = (0, _transform_deprecations.transformDeprecations)(rawSettings);

  // transform deprecated plugin settings
  for (let i = 0; i < plugins.length; i++) {
    const { spec } = plugins[i];
    const transform = await (0, _deprecation.getTransform)(spec);
    const prefix = spec.getConfigPrefix();

    // nested plugin prefixes (a.b) translate to nested objects
    const pluginSettings = (0, _lodash.get)(settings, prefix);
    if (pluginSettings) {
      // flattened settings are expected to be converted to nested objects
      // a.b = true => { a: { b: true }}
      (0, _lodash.set)(settings, prefix, transform(pluginSettings));
    }
  }

  // remove config values from disabled plugins
  for (const spec of disabledPluginSpecs) {
    (0, _utils.unset)(settings, spec.getConfigPrefix());
  }

  const inputKeys = getFlattenedKeys(settings);
  const appliedKeys = getFlattenedKeys(configValues);

  if (inputKeys.includes('env')) {
    // env is a special case key, see https://github.com/elastic/kibana/blob/848bf17b/src/server/config/config.js#L74
    // where it is deleted from the settings before being injected into the schema via context and
    // then renamed to `env.name` https://github.com/elastic/kibana/blob/848bf17/src/server/config/schema.js#L17
    inputKeys[inputKeys.indexOf('env')] = 'env.name';
  }

  // Filter out keys that are marked as used in the core (e.g. by new core plugins).
  return (0, _lodash.difference)(inputKeys, appliedKeys).filter(unusedConfigKey => !coreHandledConfigPaths.some(usedInCoreConfigKey => unusedConfigKey.startsWith(usedInCoreConfigKey)));
}

exports.default = async function (kbnServer, server, config) {
  server.decorate('server', 'config', function () {
    return kbnServer.config;
  });

  const unusedKeys = await getUnusedConfigKeys(kbnServer.core.handledConfigPaths, kbnServer.plugins, kbnServer.disabledPluginSpecs, kbnServer.settings, config.get());

  if (!unusedKeys.length) {
    return;
  }

  const formattedUnusedKeys = unusedKeys.map(key => `"${key}"`);
  const desc = formattedUnusedKeys.length === 1 ? 'setting was' : 'settings were';

  const error = new Error(`${(0, _utils.formatListAsProse)(formattedUnusedKeys)} ${desc} not applied. ` + 'Check for spelling errors and ensure that expected ' + 'plugins are installed.');

  error.code = 'InvalidConfig';
  error.processExitCode = 64;
  throw error;
};

module.exports = exports['default'];