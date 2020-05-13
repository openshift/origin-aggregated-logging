'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.Metrics = undefined;

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; }; /*
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

var _os = require('os');

var _os2 = _interopRequireDefault(_os);

var _v = require('v8');

var _v2 = _interopRequireDefault(_v);

var _lodash = require('lodash');

var _case_conversion = require('../../../utils/case_conversion');

var _cgroup = require('./cgroup');

var _get_os_info = require('./get_os_info');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const requestDefaults = {
  disconnects: 0,
  statusCodes: {},
  total: 0
};

class Metrics {
  constructor(config, server) {
    this.config = config;
    this.server = server;
    this.checkCGroupStats = true;
  }

  static getStubMetrics() {
    return {
      process: {
        memory: {
          heap: {}
        }
      },
      os: {
        cpu: {},
        memory: {}
      },
      response_times: {},
      requests: {}
    };
  }

  async capture(hapiEvent) {
    const timestamp = new Date().toISOString();
    const event = await this.captureEvent(hapiEvent);
    const cgroup = await this.captureCGroupsIfAvailable();

    const metrics = {
      last_updated: timestamp,
      collection_interval_in_millis: this.config.get('ops.interval')
    };

    return (0, _lodash.merge)(metrics, event, cgroup);
  }

  async captureEvent(hapiEvent) {
    const heapStats = _v2.default.getHeapStatistics();
    const port = this.config.get('server.port');
    const avgInMillis = (0, _lodash.get)(hapiEvent, ['responseTimes', port, 'avg']); // sadly, it's possible for this to be NaN
    const maxInMillis = (0, _lodash.get)(hapiEvent, ['responseTimes', port, 'max']);

    return {
      process: {
        memory: {
          heap: {
            // https://nodejs.org/docs/latest-v8.x/api/process.html#process_process_memoryusage
            total_in_bytes: (0, _lodash.get)(hapiEvent, 'psmem.heapTotal'),
            used_in_bytes: (0, _lodash.get)(hapiEvent, 'psmem.heapUsed'),
            size_limit: heapStats.heap_size_limit
          },
          resident_set_size_in_bytes: (0, _lodash.get)(hapiEvent, 'psmem.rss')
        },
        event_loop_delay: (0, _lodash.get)(hapiEvent, 'psdelay'),
        pid: process.pid,
        uptime_in_millis: process.uptime() * 1000
      },
      os: _extends({
        load: {
          '1m': (0, _lodash.get)(hapiEvent, 'osload.0'),
          '5m': (0, _lodash.get)(hapiEvent, 'osload.1'),
          '15m': (0, _lodash.get)(hapiEvent, 'osload.2')
        },
        memory: {
          total_in_bytes: _os2.default.totalmem(),
          free_in_bytes: _os2.default.freemem(),
          used_in_bytes: (0, _lodash.get)(hapiEvent, 'osmem.total') - (0, _lodash.get)(hapiEvent, 'osmem.free')
        },
        uptime_in_millis: _os2.default.uptime() * 1000
      }, (await (0, _get_os_info.getOSInfo)())),
      response_times: {
        avg_in_millis: isNaN(avgInMillis) ? undefined : avgInMillis, // convert NaN to undefined
        max_in_millis: maxInMillis
      },
      requests: _extends({}, requestDefaults, (0, _case_conversion.keysToSnakeCaseShallow)((0, _lodash.get)(hapiEvent, ['requests', port]))),
      concurrent_connections: hapiEvent.concurrent_connections
    };
  }

  async captureCGroups() {
    try {
      const cgroup = await (0, _cgroup.getAllStats)({
        cpuPath: this.config.get('cpu.cgroup.path.override'),
        cpuAcctPath: this.config.get('cpuacct.cgroup.path.override')
      });

      if ((0, _lodash.isObject)(cgroup)) {
        return {
          os: {
            cgroup
          }
        };
      }
    } catch (e) {
      this.server.log(['error', 'metrics', 'cgroup'], e);
    }
  }

  async captureCGroupsIfAvailable() {
    if (this.checkCGroupStats === true) {
      const cgroup = await this.captureCGroups();

      if ((0, _lodash.isObject)(cgroup)) {
        return cgroup;
      }

      this.checkCGroupStats = false;
    }
  }
}
exports.Metrics = Metrics;