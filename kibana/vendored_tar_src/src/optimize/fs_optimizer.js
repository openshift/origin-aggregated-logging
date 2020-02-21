'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _base_optimizer = require('./base_optimizer');

var _base_optimizer2 = _interopRequireDefault(_base_optimizer);

var _bluebird = require('bluebird');

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

class FsOptimizer extends _base_optimizer2.default {
  async run() {
    if (!this.compiler) {
      await this.init();
    }

    await (0, _bluebird.fromNode)(cb => {
      this.compiler.run((err, stats) => {
        if (err || !stats) return cb(err);

        if (this.isFailure(stats)) {
          return cb(this.failedStatsToError(stats));
        } else {
          cb(null, stats);
        }
      });
    });
  }
}
exports.default = FsOptimizer;
module.exports = exports['default'];