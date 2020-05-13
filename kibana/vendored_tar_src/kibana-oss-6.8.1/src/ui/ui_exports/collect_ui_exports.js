'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.collectUiExports = collectUiExports;

var _ui_export_defaults = require('./ui_export_defaults');

var _ui_export_types = require('./ui_export_types');

var uiExportTypeReducers = _interopRequireWildcard(_ui_export_types);

var _plugin_discovery = require('../../plugin_discovery');

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

function collectUiExports(pluginSpecs) {
  return (0, _plugin_discovery.reduceExportSpecs)(pluginSpecs, uiExportTypeReducers, _ui_export_defaults.UI_EXPORT_DEFAULTS);
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