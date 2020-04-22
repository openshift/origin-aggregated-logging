'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.UiBundlesController = undefined;

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

var _path = require('path');

var _crypto = require('crypto');

var _util = require('util');

var _fs = require('fs');

var _del = require('del');

var _del2 = _interopRequireDefault(_del);

var _minimatch = require('minimatch');

var _mkdirp = require('mkdirp');

var _mkdirp2 = _interopRequireDefault(_mkdirp);

var _ui_bundle = require('./ui_bundle');

var _app_entry_template = require('./app_entry_template');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const mkdirpAsync = (0, _util.promisify)(_mkdirp2.default);

function getWebpackAliases(pluginSpecs) {
  return pluginSpecs.reduce((aliases, spec) => {
    const publicDir = spec.getPublicDir();

    if (!publicDir) {
      return aliases;
    }

    return _extends({}, aliases, {
      [`plugins/${spec.getId()}`]: publicDir
    });
  }, {});
}

class UiBundlesController {
  constructor(kbnServer) {
    const { config, uiApps, uiExports, pluginSpecs } = kbnServer;

    this._workingDir = config.get('optimize.bundleDir');
    this._env = config.get('env.name');
    this._context = {
      env: config.get('env.name'),
      sourceMaps: config.get('optimize.sourceMaps'),
      kbnVersion: config.get('pkg.version'),
      buildNum: config.get('pkg.buildNum'),
      plugins: pluginSpecs.map(spec => spec.getId()).sort((a, b) => a.localeCompare(b))
    };

    this._filter = (0, _minimatch.makeRe)(config.get('optimize.bundleFilter') || '*', {
      noglobstar: true,
      noext: true,
      matchBase: true
    });

    this._appExtensions = uiExports.appExtensions || {};

    this._webpackAliases = _extends({}, getWebpackAliases(pluginSpecs), uiExports.webpackAliases);
    this._webpackPluginProviders = uiExports.webpackPluginProviders;
    this._webpackNoParseRules = uiExports.webpackNoParseRules;
    this._postLoaders = [];
    this._bundles = [];

    // create a bundle for each uiApp
    for (const uiApp of uiApps) {
      this.add({
        id: uiApp.getId(),
        modules: [uiApp.getMainModuleId()],
        template: _app_entry_template.appEntryTemplate
      });
    }
  }

  add(bundleSpec) {
    const {
      id,
      modules,
      template
    } = bundleSpec;

    if (this._filter.test(id)) {
      this._bundles.push(new _ui_bundle.UiBundle({
        id,
        modules,
        template,
        controller: this
      }));
    }
  }

  isDevMode() {
    return this._env === 'development';
  }

  getWebpackPluginProviders() {
    return this._webpackPluginProviders || [];
  }

  getWebpackNoParseRules() {
    return this._webpackNoParseRules;
  }

  getWorkingDir() {
    return this._workingDir;
  }

  addPostLoader(loaderSpec) {
    this._postLoaders.push(loaderSpec);
  }

  getPostLoaders() {
    return this._postLoaders;
  }

  getAliases() {
    return this._webpackAliases;
  }

  getAppExtensions() {
    return this._appExtensions;
  }

  getContext() {
    return JSON.stringify(this._context, null, '  ');
  }

  resolvePath(...args) {
    return (0, _path.resolve)(this._workingDir, ...args);
  }

  async resetBundleDir() {
    if (!(0, _fs.existsSync)(this._workingDir)) {
      // create a fresh working directory
      await mkdirpAsync(this._workingDir);
    } else {
      // delete all children of the working directory
      await (0, _del2.default)(this.resolvePath('*'), {
        // since we know that `this.resolvePath()` is going to return an absolute path based on the `optimize.bundleDir`
        // and since we don't want to require that users specify a bundleDir that is within the cwd or limit the cwd
        // directory used to run Kibana in any way we use force here
        force: true
      });
    }

    // write the entry/style files for each bundle
    for (const bundle of this._bundles) {
      await bundle.writeEntryFile();
      await bundle.touchStyleFile();
    }
  }

  getCacheDirectory(...subPath) {
    return this.resolvePath('../.cache', this.hashBundleEntries(), ...subPath);
  }

  getDescription() {
    const ids = this.getIds();
    switch (ids.length) {
      case 0:
        return '0 bundles';
      case 1:
        return `bundle for ${ids[0]}`;
      default:
        const last = ids.pop();
        const commas = ids.join(', ');
        return `bundles for ${commas} and ${last}`;
    }
  }

  hashBundleEntries() {
    const hash = (0, _crypto.createHash)('sha1');

    for (const bundle of this._bundles) {
      hash.update(`bundleEntryPath:${bundle.getEntryPath()}`);
      hash.update(`bundleEntryContent:${bundle.renderContent()}`);
    }

    return hash.digest('hex');
  }

  async areAllBundleCachesValid() {
    for (const bundle of this._bundles) {
      if (!(await bundle.isCacheValid())) {
        return false;
      }
    }

    return true;
  }

  toWebpackEntries() {
    return this._bundles.reduce((entries, bundle) => _extends({}, entries, {
      [bundle.getId()]: bundle.getEntryPath()
    }), {});
  }

  getIds() {
    return this._bundles.map(bundle => bundle.getId());
  }
}
exports.UiBundlesController = UiBundlesController;