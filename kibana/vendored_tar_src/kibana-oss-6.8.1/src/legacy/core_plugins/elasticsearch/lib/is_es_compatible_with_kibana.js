'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = isEsCompatibleWithKibana;

var _semver = require('semver');

var _semver2 = _interopRequireDefault(_semver);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function isEsCompatibleWithKibana(esVersion, kibanaVersion) {
  const esVersionNumbers = {
    major: _semver2.default.major(esVersion),
    minor: _semver2.default.minor(esVersion),
    patch: _semver2.default.patch(esVersion)
  };

  const kibanaVersionNumbers = {
    major: _semver2.default.major(kibanaVersion),
    minor: _semver2.default.minor(kibanaVersion),
    patch: _semver2.default.patch(kibanaVersion)
  };

  // Accept the next major version of ES.
  if (esVersionNumbers.major === kibanaVersionNumbers.major + 1) {
    return true;
  }

  // Reject any other major version mismatches with ES.
  if (esVersionNumbers.major !== kibanaVersionNumbers.major) {
    return false;
  }

  // Reject older minor versions of ES.
  if (esVersionNumbers.minor < kibanaVersionNumbers.minor) {
    return false;
  }

  return true;
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

/**
 * Let's weed out the ES versions that won't work with a given Kibana version.
 * 1. Major version differences will never work together.
 * 2. Older versions of ES won't work with newer versions of Kibana.
 */

module.exports = exports['default'];