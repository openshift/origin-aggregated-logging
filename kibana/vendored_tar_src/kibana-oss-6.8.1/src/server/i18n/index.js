'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; }; /*
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

exports.i18nMixin = i18nMixin;

var _path = require('path');

var _globby = require('globby');

var _globby2 = _interopRequireDefault(_globby);

var _i18n = require('@kbn/i18n');

var _utils = require('../../utils');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

async function i18nMixin(kbnServer, server, config) {
  const locale = config.get('i18n.locale');

  const translationsDirs = [(0, _utils.fromRoot)('src/ui/translations'), (0, _utils.fromRoot)('src/server/translations'), (0, _utils.fromRoot)('src/core/translations')];

  const groupedEntries = await Promise.all([...config.get('plugins.scanDirs').map(async path => {
    const entries = await (0, _globby2.default)(`*/translations/${locale}.json`, {
      cwd: path
    });
    return entries.map(entry => (0, _path.resolve)(path, entry));
  }), ...config.get('plugins.paths').map(async path => {
    const entries = await (0, _globby2.default)([`translations/${locale}.json`, `plugins/*/translations/${locale}.json`], {
      cwd: path
    });
    return entries.map(entry => (0, _path.resolve)(path, entry));
  }), ...translationsDirs.map(async path => {
    const entries = await (0, _globby2.default)(`${locale}.json`, {
      cwd: path
    });
    return entries.map(entry => (0, _path.resolve)(path, entry));
  })]);

  const translationPaths = [].concat(...groupedEntries);
  _i18n.i18nLoader.registerTranslationFiles(translationPaths);

  const translations = await _i18n.i18nLoader.getTranslationsByLocale(locale);
  _i18n.i18n.init(Object.freeze(_extends({
    locale
  }, translations)));
  server.decorate('server', 'getTranslationsFilePaths', () => translationPaths);
}