'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.parseSingleFile = parseSingleFile;
exports.parseSingleFileSync = parseSingleFileSync;
exports.parseEntries = parseEntries;

var _can_require = require('./can_require');

var _fs = require('fs');

var _path = require('path');

var _util = require('util');

var _parser = require('@babel/parser');

var parser = _interopRequireWildcard(_parser);

var _traverse = require('@babel/traverse');

var _traverse2 = _interopRequireDefault(_traverse);

var _common_babel_parser_options = require('@kbn/babel-preset/common_babel_parser_options');

var babelParserOptions = _interopRequireWildcard(_common_babel_parser_options);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

const read = (0, _util.promisify)(_fs.readFile); /*
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

function _cannotParseFile(filePath) {
  return (0, _path.extname)(filePath) !== '.js';
}

function _parseAndTraverseFileContent(fileContent, visitorsGenerator) {
  const results = [];

  // Parse and get the code AST
  // All the babel parser plugins
  // were enabled
  const ast = parser.parse(fileContent, babelParserOptions);

  // Loop through the code AST with
  // the defined visitors
  (0, _traverse2.default)(ast, visitorsGenerator(results));

  return results;
}

async function parseSingleFile(filePath, visitorsGenerator) {
  // Don't parse any other files than .js ones
  if (_cannotParseFile(filePath)) {
    return [];
  }

  // Read the file
  const content = await read(filePath, { encoding: 'utf8' });

  // return the results found on parse and traverse
  // the file content with the given visitors
  return _parseAndTraverseFileContent(content, visitorsGenerator);
}

function parseSingleFileSync(filePath, visitorsGenerator) {
  // Don't parse any other files than .js ones
  if (_cannotParseFile(filePath)) {
    return [];
  }

  // Read the file
  const content = (0, _fs.readFileSync)(filePath, { encoding: 'utf8' });

  // return the results found on parse and traverse
  // the file content with the given visitors
  return _parseAndTraverseFileContent(content, visitorsGenerator);
}

async function parseEntries(cwd, entries, strategy, results, wasParsed = {}) {
  // Assure that we always have a cwd
  const sanitizedCwd = cwd || process.cwd();

  // Test each entry against canRequire function
  const entriesQueue = entries.map(entry => (0, _can_require.canRequire)(sanitizedCwd, entry));

  while (entriesQueue.length) {
    // Get the first element in the queue as
    // select it as our current entry to parse
    const mainEntry = entriesQueue.shift();

    // Avoid parse the current entry if it is not valid
    // or it was already parsed
    if (typeof mainEntry !== 'string' || wasParsed[mainEntry]) {
      continue;
    }

    // Find new entries and adds them to the end of the queue
    entriesQueue.push(...(await strategy(sanitizedCwd, parseSingleFile, mainEntry, wasParsed, results)));

    // Mark the current main entry as already parsed
    wasParsed[mainEntry] = true;
  }

  return results;
}