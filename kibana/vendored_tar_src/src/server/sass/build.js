'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.Build = undefined;

var _path = require('path');

var _path2 = _interopRequireDefault(_path);

var _util = require('util');

var _fs = require('fs');

var _fs2 = _interopRequireDefault(_fs);

var _nodeSass = require('node-sass');

var _nodeSass2 = _interopRequireDefault(_nodeSass);

var _autoprefixer = require('autoprefixer');

var _autoprefixer2 = _interopRequireDefault(_autoprefixer);

var _postcss = require('postcss');

var _postcss2 = _interopRequireDefault(_postcss);

var _mkdirp = require('mkdirp');

var _mkdirp2 = _interopRequireDefault(_mkdirp);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const renderSass = (0, _util.promisify)(_nodeSass2.default.render); /*
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

const writeFile = (0, _util.promisify)(_fs2.default.writeFile);
const mkdirpAsync = (0, _util.promisify)(_mkdirp2.default);

class Build {
  constructor(source, log, targetPath) {
    this.source = source;
    this.log = log;
    this.targetPath = targetPath;
    this.includedFiles = [source];
  }

  /**
   * Glob based on source path
   */

  async buildIfIncluded(path) {
    if (this.includedFiles && this.includedFiles.includes(path)) {
      await this.build();
      return true;
    }

    return false;
  }

  /**
   * Transpiles SASS and writes CSS to output
   */

  async build() {
    const rendered = await renderSass({
      file: this.source,
      outFile: this.targetPath,
      sourceMap: true,
      sourceMapEmbed: true,
      includePaths: [_path2.default.resolve(__dirname, '../..'), _path2.default.resolve(__dirname, '../../../node_modules')]
    });

    const prefixed = (0, _postcss2.default)([_autoprefixer2.default]).process(rendered.css);

    this.includedFiles = rendered.stats.includedFiles;

    await mkdirpAsync(_path2.default.dirname(this.targetPath));
    await writeFile(this.targetPath, prefixed.css);

    return this;
  }
}
exports.Build = Build;