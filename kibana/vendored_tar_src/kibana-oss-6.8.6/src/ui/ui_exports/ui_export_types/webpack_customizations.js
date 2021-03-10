'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.noParse = exports.__webpackPluginProvider__ = exports.__bundleProvider__ = exports.__globalImportAliases__ = undefined;

var _path = require('path');

var _lodash = require('lodash');

var _reduce = require('./reduce');

var _modify_reduce = require('./modify_reduce');

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

const __globalImportAliases__ = exports.__globalImportAliases__ = (0, _modify_reduce.wrap)((0, _modify_reduce.alias)('webpackAliases'), (0, _modify_reduce.uniqueKeys)('__globalImportAliases__'), _reduce.mergeAtType);
const __bundleProvider__ = exports.__bundleProvider__ = (0, _modify_reduce.wrap)((0, _modify_reduce.alias)('uiBundleProviders'), _reduce.flatConcatAtType);
const __webpackPluginProvider__ = exports.__webpackPluginProvider__ = (0, _modify_reduce.wrap)((0, _modify_reduce.alias)('webpackPluginProviders'), _reduce.flatConcatAtType);
const noParse = exports.noParse = (0, _modify_reduce.wrap)((0, _modify_reduce.alias)('webpackNoParseRules'), (0, _modify_reduce.mapSpec)(rule => {
  if (typeof rule === 'string') {
    return new RegExp(`${(0, _path.isAbsolute)(rule) ? '^' : ''}${(0, _lodash.escapeRegExp)(rule)}`);
  }

  if (rule instanceof RegExp) {
    return rule;
  }

  throw new Error('Expected noParse rule to be a string or regexp');
}), _reduce.flatConcatAtType);