'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.DllCompiler = undefined;

var _dll_config_model = require('./dll_config_model');

var _utils = require('../../utils');

var _public_path_placeholder = require('../public_path_placeholder');

var _fs = require('fs');

var _fs2 = _interopRequireDefault(_fs);

var _mkdirp = require('mkdirp');

var _mkdirp2 = _interopRequireDefault(_mkdirp);

var _webpack = require('webpack');

var _webpack2 = _interopRequireDefault(_webpack);

var _util = require('util');

var _path = require('path');

var _path2 = _interopRequireDefault(_path);

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

const readFileAsync = (0, _util.promisify)(_fs2.default.readFile);
const mkdirpAsync = (0, _util.promisify)(_mkdirp2.default);
const existsAsync = (0, _util.promisify)(_fs2.default.exists);
const writeFileAsync = (0, _util.promisify)(_fs2.default.writeFile);

class DllCompiler {
  static getRawDllConfig(uiBundles = {}, babelLoaderCacheDir = '', threadLoaderPoolConfig = {}) {
    return {
      uiBundles,
      babelLoaderCacheDir,
      threadLoaderPoolConfig,
      context: (0, _utils.fromRoot)('.'),
      entryName: 'vendors',
      dllName: '[name]',
      manifestName: '[name]',
      styleName: '[name]',
      entryExt: '.entry.dll.js',
      dllExt: '.bundle.dll.js',
      manifestExt: '.manifest.dll.json',
      styleExt: '.style.dll.css',
      outputPath: (0, _utils.fromRoot)('built_assets/dlls'),
      publicPath: _public_path_placeholder.PUBLIC_PATH_PLACEHOLDER
    };
  }

  constructor(uiBundles, threadLoaderPoolConfig, logWithMetadata) {
    this.rawDllConfig = DllCompiler.getRawDllConfig(uiBundles, uiBundles.getCacheDirectory('babel'), threadLoaderPoolConfig);
    this.logWithMetadata = logWithMetadata || (() => null);
  }

  async init() {
    await this.ensureEntryFileExists();
    await this.ensureManifestFileExists();
    await this.ensureOutputPathExists();
  }

  async upsertEntryFile(content) {
    await this.upsertFile(this.getEntryPath(), content);
  }

  async upsertFile(filePath, content = '') {
    await this.ensurePathExists(filePath);
    await writeFileAsync(filePath, content, 'utf8');
  }

  getDllPath() {
    return this.resolvePath(`${this.rawDllConfig.entryName}${this.rawDllConfig.dllExt}`);
  }

  getEntryPath() {
    return this.resolvePath(`${this.rawDllConfig.entryName}${this.rawDllConfig.entryExt}`);
  }

  getManifestPath() {
    return this.resolvePath(`${this.rawDllConfig.entryName}${this.rawDllConfig.manifestExt}`);
  }

  getStylePath() {
    return this.resolvePath(`${this.rawDllConfig.entryName}${this.rawDllConfig.styleExt}`);
  }

  async ensureEntryFileExists() {
    await this.ensureFileExists(this.getEntryPath());
  }

  async ensureManifestFileExists() {
    await this.ensureFileExists(this.getManifestPath(), JSON.stringify({
      name: this.rawDllConfig.entryName,
      content: {}
    }));
  }

  async ensureStyleFileExists() {
    await this.ensureFileExists(this.getStylePath());
  }

  async ensureFileExists(filePath, content) {
    const exists = await this.ensurePathExists(filePath);

    if (!exists) {
      await this.upsertFile(filePath, content);
    }
  }

  async ensurePathExists(filePath) {
    const exists = await existsAsync(filePath);

    if (!exists) {
      await mkdirpAsync(_path2.default.dirname(filePath));
    }

    return exists;
  }

  async ensureOutputPathExists() {
    await this.ensurePathExists(this.rawDllConfig.outputPath);
  }

  dllExistsSync() {
    return this.existsSync(this.getDllPath());
  }

  existsSync(filePath) {
    return _fs2.default.existsSync(filePath);
  }

  resolvePath() {
    return _path2.default.resolve(this.rawDllConfig.outputPath, ...arguments);
  }

  async readEntryFile() {
    return await this.readFile(this.getEntryPath());
  }

  async readFile(filePath, content) {
    await this.ensureFileExists(filePath, content);
    return await readFileAsync(filePath, 'utf8');
  }

  async run(dllEntries) {
    const dllConfig = this.dllConfigGenerator(this.rawDllConfig);
    await this.upsertEntryFile(dllEntries);
    await this.runWebpack(dllConfig());

    // Style dll file isn't always created but we are
    // expecting it to exist always as we are referencing
    // it from the bootstrap template
    //
    // NOTE: We should review the way we deal with the css extraction
    // in ours webpack builds. The industry standard is about to
    // only extract css for production but we are extracting it
    // in every single compilation.
    await this.ensureStyleFileExists();
  }

  dllConfigGenerator(dllConfig) {
    return _dll_config_model.configModel.bind(this, dllConfig);
  }

  async runWebpack(config) {
    return new Promise((resolve, reject) => {
      this.logWithMetadata(['info', 'optimize:dynamic_dll_plugin'], 'Client vendors dll compilation started');

      (0, _webpack2.default)(config, (err, stats) => {
        // If a critical error occurs or we have
        // errors in the stats compilation,
        // reject the promise and logs the errors
        const webpackErrors = err || stats.hasErrors() && stats.toString({
          all: false,
          colors: true,
          errors: true,
          errorDetails: true,
          moduleTrace: true
        });

        if (webpackErrors) {
          this.logWithMetadata(['fatal', 'optimize:dynamic_dll_plugin'], `Client vendors dll compilation failed`);
          return reject(webpackErrors);
        }

        // Otherwise let it proceed
        this.logWithMetadata(['info', 'optimize:dynamic_dll_plugin'], `Client vendors dll compilation finished with success`);
        return resolve(stats);
      });
    });
  }
}
exports.DllCompiler = DllCompiler;