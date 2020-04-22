'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.UiBundle = undefined;

var _bluebird = require('bluebird');

var _fs = require('fs');

// We normalize all path separators to `/` in generated files
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

function normalizePath(path) {
  return path.replace(/[\\\/]+/g, '/');
}

class UiBundle {
  constructor(options) {
    const {
      id,
      modules,
      template,
      controller
    } = options;

    this._id = id;
    this._modules = modules;
    this._template = template;
    this._controller = controller;
  }

  getId() {
    return this._id;
  }

  getContext() {
    return this._controller.getContext();
  }

  getEntryPath() {
    return this._controller.resolvePath(`${this.getId()}.entry.js`);
  }

  getStylePath() {
    return this._controller.resolvePath(`${this.getId()}.style.css`);
  }

  getOutputPath() {
    return this._controller.resolvePath(`${this.getId()}.bundle.js`);
  }

  getRequires() {
    return this._modules.map(module => `require('${normalizePath(module)}');`);
  }

  renderContent() {
    return this._template(this);
  }

  async readEntryFile() {
    try {
      const content = await (0, _bluebird.fromNode)(cb => (0, _fs.readFile)(this.getEntryPath(), cb));
      return content.toString('utf8');
    } catch (e) {
      return null;
    }
  }

  async writeEntryFile() {
    return await (0, _bluebird.fromNode)(cb => (0, _fs.writeFile)(this.getEntryPath(), this.renderContent(), 'utf8', cb));
  }

  async touchStyleFile() {
    return await (0, _bluebird.fromNode)(cb => (0, _fs.writeFile)(this.getStylePath(), '', 'utf8', cb));
  }

  /**
   * Determine if the cache for this bundle is valid by
   * checking that the entry file exists, has the content we
   * expect based on the argument for this bundle, and that both
   * the style file and output for this bundle exist. In this
   * scenario we assume the cache is valid.
   *
   * When the `optimize.useBundleCache` config is set to `false`
   * (the default when running in development) we don't even call
   * this method and bundles are always recreated.
   */
  async isCacheValid() {
    if ((await this.readEntryFile()) !== this.renderContent()) {
      return false;
    }

    try {
      await (0, _bluebird.fromNode)(cb => (0, _fs.stat)(this.getOutputPath(), cb));
      await (0, _bluebird.fromNode)(cb => (0, _fs.stat)(this.getStylePath(), cb));
      return true;
    } catch (e) {
      return false;
    }
  }

  toJSON() {
    return {
      id: this._id,
      modules: this._modules,
      entryPath: this.getEntryPath(),
      outputPath: this.getOutputPath()
    };
  }
}
exports.UiBundle = UiBundle;