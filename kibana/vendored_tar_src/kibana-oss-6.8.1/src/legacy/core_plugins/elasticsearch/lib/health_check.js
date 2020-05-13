'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

exports.default = function (plugin, server) {
  const config = server.config();
  const callAdminAsKibanaUser = server.plugins.elasticsearch.getCluster('admin').callWithInternalUser;
  const callDataAsKibanaUser = server.plugins.elasticsearch.getCluster('data').callWithInternalUser;
  const REQUEST_DELAY = config.get('elasticsearch.healthCheck.delay');

  plugin.status.yellow('Waiting for Elasticsearch');
  function waitForPong(callWithInternalUser) {
    return callWithInternalUser('ping').catch(function (err) {
      if (!(err instanceof NoConnections)) throw err;
      plugin.status.red(`Unable to connect to Elasticsearch.`);
      return _bluebird2.default.delay(REQUEST_DELAY).then(waitForPong.bind(null, callWithInternalUser));
    });
  }

  function waitUntilReady() {
    return new _bluebird2.default(resolve => {
      plugin.status.once('green', resolve);
    });
  }

  function waitForEsVersion() {
    return (0, _ensure_es_version.ensureEsVersion)(server, _kibana_version2.default.get()).catch(err => {
      plugin.status.red(err);
      return _bluebird2.default.delay(REQUEST_DELAY).then(waitForEsVersion);
    });
  }

  function setGreenStatus() {
    return plugin.status.green('Ready');
  }

  function check() {
    const healthCheck = waitForPong(callAdminAsKibanaUser).then(waitForEsVersion).then(() => (0, _ensure_not_tribe.ensureNotTribe)(callAdminAsKibanaUser)).then(() => {
      if (config.get('elasticsearch.tribe.hosts')) {
        return waitForPong(callDataAsKibanaUser).then(() => (0, _ensure_es_version.ensureEsVersion)(server, _kibana_version2.default.get(), callDataAsKibanaUser));
      }
    });

    return healthCheck.then(setGreenStatus).catch(err => plugin.status.red(err));
  }

  let timeoutId = null;

  function scheduleCheck(ms) {
    if (timeoutId) return;

    const myId = setTimeout(function () {
      check().finally(function () {
        if (timeoutId === myId) startorRestartChecking();
      });
    }, ms);

    timeoutId = myId;
  }

  function startorRestartChecking() {
    scheduleCheck(stopChecking() ? REQUEST_DELAY : 1);
  }

  function stopChecking() {
    if (!timeoutId) return false;
    clearTimeout(timeoutId);
    timeoutId = null;
    return true;
  }

  server.ext('onPreStop', stopChecking);

  return {
    waitUntilReady: waitUntilReady,
    run: check,
    start: startorRestartChecking,
    stop: stopChecking,
    isRunning: function () {
      return !!timeoutId;
    }
  };
};

var _bluebird = require('bluebird');

var _bluebird2 = _interopRequireDefault(_bluebird);

var _elasticsearch = require('elasticsearch');

var _elasticsearch2 = _interopRequireDefault(_elasticsearch);

var _kibana_version = require('./kibana_version');

var _kibana_version2 = _interopRequireDefault(_kibana_version);

var _ensure_es_version = require('./ensure_es_version');

var _ensure_not_tribe = require('./ensure_not_tribe');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const NoConnections = _elasticsearch2.default.errors.NoConnections; /*
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