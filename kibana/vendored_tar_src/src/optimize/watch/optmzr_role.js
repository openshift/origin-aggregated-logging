'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _path = require('path');

var _watch_server = require('./watch_server');

var _watch_server2 = _interopRequireDefault(_watch_server);

var _watch_optimizer = require('./watch_optimizer');

var _watch_optimizer2 = _interopRequireDefault(_watch_optimizer);

var _dynamic_dll_plugin = require('../dynamic_dll_plugin');

var _watch_cache = require('./watch_cache');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.default = async (kbnServer, kibanaHapiServer, config) => {
  const logWithMetadata = (tags, message, metadata) => kibanaHapiServer.logWithMetadata(tags, message, metadata);

  const watchOptimizer = new _watch_optimizer2.default({
    logWithMetadata,
    uiBundles: kbnServer.uiBundles,
    profile: config.get('optimize.profile'),
    sourceMaps: config.get('optimize.sourceMaps'),
    prebuild: config.get('optimize.watchPrebuild'),
    watchCache: new _watch_cache.WatchCache({
      logWithMetadata,
      outputPath: config.get('path.data'),
      dllsPath: _dynamic_dll_plugin.DllCompiler.getRawDllConfig().outputPath,
      cachePath: (0, _path.resolve)(kbnServer.uiBundles.getCacheDirectory(), '../')
    })
  });

  const server = new _watch_server2.default(config.get('optimize.watchHost'), config.get('optimize.watchPort'), config.get('server.basePath'), watchOptimizer);

  watchOptimizer.status$.subscribe({
    next(status) {
      process.send(['OPTIMIZE_STATUS', {
        success: status.type === _watch_optimizer.STATUS.SUCCESS
      }]);
    }
  });

  let ready = false;

  const sendReady = () => {
    if (!process.connected) return;
    process.send(['WORKER_BROADCAST', { optimizeReady: ready }]);
  };

  process.on('message', msg => {
    if (msg && msg.optimizeReady === '?') sendReady();
  });

  sendReady();

  await server.init();

  ready = true;
  sendReady();
}; /*
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

module.exports = exports['default'];