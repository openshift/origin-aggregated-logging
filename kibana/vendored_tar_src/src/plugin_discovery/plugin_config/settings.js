'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getSettings = getSettings;

var _lodash = require('lodash');

var _config = require('../../server/config');

var serverConfig = _interopRequireWildcard(_config);

var _deprecation = require('../../deprecation');

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

/**
 *  Get the settings for a pluginSpec from the raw root settings while
 *  optionally calling logDeprecation() with warnings about deprecated
 *  settings that were used
 *  @param  {PluginSpec} spec
 *  @param  {Object} rootSettings
 *  @param  {Function} [logDeprecation]
 *  @return {Promise<Object>}
 */
async function getSettings(spec, rootSettings, logDeprecation) {
  const prefix = spec.getConfigPrefix();
  const rawSettings = (0, _lodash.get)(serverConfig.transformDeprecations(rootSettings), prefix);
  const transform = await (0, _deprecation.getTransform)(spec);
  return transform(rawSettings, logDeprecation);
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