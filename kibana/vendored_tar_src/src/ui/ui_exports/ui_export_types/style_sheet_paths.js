'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.styleSheetPaths = undefined;

var _path = require('path');

var _path2 = _interopRequireDefault(_path);

var _fs = require('fs');

var _reduce = require('./reduce');

var _modify_reduce = require('./modify_reduce');

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

const OK_EXTNAMES = ['.css', '.scss'];

function normalize(localPath, type, pluginSpec) {
  const pluginId = pluginSpec.getId();
  const publicDir = _path2.default.normalize(pluginSpec.getPublicDir());
  const extname = _path2.default.extname(localPath);

  if (!OK_EXTNAMES.includes(extname)) {
    throw new Error(`[plugin:${pluginId}] uiExports.styleSheetPaths supported extensions [${OK_EXTNAMES.join(', ')}], got "${extname}"`);
  }

  if (!_path2.default.isAbsolute(localPath)) {
    throw new Error(`[plugin:${pluginId}] uiExports.styleSheetPaths must be an absolute path, got "${localPath}"`);
  }

  if (!_path2.default.normalize(localPath).startsWith(publicDir)) {
    throw new Error(`[plugin:${pluginId}] uiExports.styleSheetPaths must be child of publicDir [${publicDir}]`);
  }

  // replace the extension of localPath to be .css
  // publicPath will always point to the css file
  const localCssPath = localPath.slice(0, -extname.length) + '.css';

  // update localPath to point to the .css file if it exists and
  // the .scss path does not, which is the case for built plugins
  if (extname === '.scss' && !(0, _fs.existsSync)(localPath) && (0, _fs.existsSync)(localCssPath)) {
    localPath = localCssPath;
  }

  // get the path of the stylesheet relative to the public dir for the plugin
  let relativePath = _path2.default.relative(publicDir, localCssPath);

  // replace back slashes on windows
  relativePath = relativePath.split('\\').join('/');

  const publicPath = `plugins/${pluginSpec.getId()}/${relativePath}`;

  return {
    localPath,
    publicPath
  };
}

const styleSheetPaths = exports.styleSheetPaths = (0, _modify_reduce.wrap)((0, _modify_reduce.mapSpec)(normalize), _reduce.flatConcatAtType);