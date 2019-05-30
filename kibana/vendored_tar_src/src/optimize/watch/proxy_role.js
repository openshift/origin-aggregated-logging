'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _bundles_route = require('../bundles_route');

var _bluebird = require('bluebird');

var _lodash = require('lodash');

exports.default = (kbnServer, server, config) => {

  server.route((0, _bundles_route.createProxyBundlesRoute)({
    host: config.get('optimize.watchHost'),
    port: config.get('optimize.watchPort')
  }));

  return (0, _bluebird.fromNode)(cb => {
    const timeout = setTimeout(() => {
      cb(new Error('Timeout waiting for the optimizer to become ready'));
    }, config.get('optimize.watchProxyTimeout'));

    const waiting = (0, _lodash.once)(() => {
      server.log(['info', 'optimize'], 'Waiting for optimizer to be ready');
    });

    if (!process.connected) return;

    process.send(['WORKER_BROADCAST', { optimizeReady: '?' }]);
    process.on('message', msg => {
      switch ((0, _lodash.get)(msg, 'optimizeReady')) {
        case true:
          clearTimeout(timeout);
          cb();
          break;
        case false:
          waiting();
          break;
      }
    });
  });
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