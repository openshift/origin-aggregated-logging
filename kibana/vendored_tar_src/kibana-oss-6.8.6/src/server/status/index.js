'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.statusMixin = statusMixin;

var _server_status = require('./server_status');

var _server_status2 = _interopRequireDefault(_server_status);

var _metrics = require('./lib/metrics');

var _routes = require('./routes');

var _collectors = require('./collectors');

var _oppsy = require('oppsy');

var _oppsy2 = _interopRequireDefault(_oppsy);

var _lodash = require('lodash');

var _get_os_info = require('./lib/get_os_info');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function statusMixin(kbnServer, server, config) {
  kbnServer.status = new _server_status2.default(kbnServer.server);

  const statsCollector = (0, _collectors.getOpsStatsCollector)(server, kbnServer);
  const { collectorSet } = server.usage;
  collectorSet.register(statsCollector);

  const metrics = new _metrics.Metrics(config, server);

  const oppsy = new _oppsy2.default(server);
  oppsy.on('ops', event => {
    // Oppsy has a bad race condition that will modify this data before
    // we ship it off to the buffer. Let's create our copy first.
    event = (0, _lodash.cloneDeep)(event);
    // Oppsy used to provide this, but doesn't anymore. Grab it ourselves.
    server.listener.getConnections((_, count) => {
      event.concurrent_connections = count;

      // captures (performs transforms on) the latest event data and stashes
      // the metrics for status/stats API payload
      metrics.capture(event).then(data => {
        kbnServer.metrics = data;
      });
    });
  });
  oppsy.start(config.get('ops.interval'));

  // init routes
  (0, _routes.registerStatusPage)(kbnServer, server, config);
  (0, _routes.registerStatusApi)(kbnServer, server, config);
  (0, _routes.registerStatsApi)(kbnServer, server, config);

  // expore shared functionality
  server.decorate('server', 'getOSInfo', _get_os_info.getOSInfo);
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