'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.uiMixin = uiMixin;

var _ui_exports = require('./ui_exports');

var _field_formats = require('./field_formats');

var _tutorials_mixin = require('./tutorials_mixin');

var _ui_apps = require('./ui_apps');

var _ui_bundles = require('./ui_bundles');

var _ui_nav_links = require('./ui_nav_links');

var _ui_render = require('./ui_render');

var _ui_settings = require('./ui_settings');

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

async function uiMixin(kbnServer) {
  await kbnServer.mixin(_ui_exports.uiExportsMixin);
  await kbnServer.mixin(_ui_apps.uiAppsMixin);
  await kbnServer.mixin(_ui_bundles.uiBundlesMixin);
  await kbnServer.mixin(_ui_settings.uiSettingsMixin);
  await kbnServer.mixin(_field_formats.fieldFormatsMixin);
  await kbnServer.mixin(_tutorials_mixin.tutorialsMixin);
  await kbnServer.mixin(_ui_nav_links.uiNavLinksMixin);
  await kbnServer.mixin(_ui_render.uiRenderMixin);
}