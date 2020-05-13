'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.readControlGroups = readControlGroups;
exports.readCPUStat = readCPUStat;
exports.getAllStats = getAllStats;

var _fs = require('fs');

var _fs2 = _interopRequireDefault(_fs);

var _bluebird = require('bluebird');

var _path = require('path');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// Logic from elasticsearch/core/src/main/java/org/elasticsearch/monitor/os/OsProbe.java

const CONTROL_GROUP_RE = new RegExp('\\d+:([^:]+):(/.*)'); /*
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

const CONTROLLER_SEPARATOR_RE = ',';

const PROC_SELF_CGROUP_FILE = '/proc/self/cgroup';
const PROC_CGROUP_CPU_DIR = '/sys/fs/cgroup/cpu';
const PROC_CGROUP_CPUACCT_DIR = '/sys/fs/cgroup/cpuacct';

const GROUP_CPUACCT = 'cpuacct';
const CPUACCT_USAGE_FILE = 'cpuacct.usage';

const GROUP_CPU = 'cpu';
const CPU_FS_PERIOD_US_FILE = 'cpu.cfs_period_us';
const CPU_FS_QUOTA_US_FILE = 'cpu.cfs_quota_us';
const CPU_STATS_FILE = 'cpu.stat';

const readFile = (0, _bluebird.promisify)(_fs2.default.readFile);

function readControlGroups() {
  return readFile(PROC_SELF_CGROUP_FILE).then(data => {
    const response = {};

    data.toString().split(/\n/).forEach(line => {
      const matches = line.match(CONTROL_GROUP_RE);

      if (matches === null) {
        return;
      }

      const controllers = matches[1].split(CONTROLLER_SEPARATOR_RE);
      controllers.forEach(controller => {
        response[controller] = matches[2];
      });
    });

    return response;
  });
}

function fileContentsToInteger(path) {
  return readFile(path).then(data => {
    return parseInt(data.toString(), 10);
  });
}

function readCPUAcctUsage(controlGroup) {
  return fileContentsToInteger((0, _path.join)(PROC_CGROUP_CPUACCT_DIR, controlGroup, CPUACCT_USAGE_FILE));
}

function readCPUFsPeriod(controlGroup) {
  return fileContentsToInteger((0, _path.join)(PROC_CGROUP_CPU_DIR, controlGroup, CPU_FS_PERIOD_US_FILE));
}

function readCPUFsQuota(controlGroup) {
  return fileContentsToInteger((0, _path.join)(PROC_CGROUP_CPU_DIR, controlGroup, CPU_FS_QUOTA_US_FILE));
}

function readCPUStat(controlGroup) {
  return new Promise((resolve, reject) => {
    const stat = {
      number_of_elapsed_periods: -1,
      number_of_times_throttled: -1,
      time_throttled_nanos: -1
    };

    readFile((0, _path.join)(PROC_CGROUP_CPU_DIR, controlGroup, CPU_STATS_FILE)).then(data => {
      data.toString().split(/\n/).forEach(line => {
        const fields = line.split(/\s+/);

        switch (fields[0]) {
          case 'nr_periods':
            stat.number_of_elapsed_periods = parseInt(fields[1], 10);
            break;

          case 'nr_throttled':
            stat.number_of_times_throttled = parseInt(fields[1], 10);
            break;

          case 'throttled_time':
            stat.time_throttled_nanos = parseInt(fields[1], 10);
            break;
        }
      });

      resolve(stat);
    }).catch(err => {
      if (err.code === 'ENOENT') {
        return resolve(stat);
      }

      reject(err);
    });
  });
}

function getAllStats(options = {}) {
  return new Promise((resolve, reject) => {
    readControlGroups().then(groups => {
      const cpuPath = options.cpuPath || groups[GROUP_CPU];
      const cpuAcctPath = options.cpuAcctPath || groups[GROUP_CPUACCT];

      // prevents undefined cgroup paths
      if (!cpuPath || !cpuAcctPath) {
        return resolve(null);
      }

      return Promise.all([readCPUAcctUsage(cpuAcctPath), readCPUFsPeriod(cpuPath), readCPUFsQuota(cpuPath), readCPUStat(cpuPath)]).then(([cpuAcctUsage, cpuFsPeriod, cpuFsQuota, cpuStat]) => {
        resolve({
          cpuacct: {
            control_group: cpuAcctPath,
            usage_nanos: cpuAcctUsage
          },

          cpu: {
            control_group: cpuPath,
            cfs_period_micros: cpuFsPeriod,
            cfs_quota_micros: cpuFsQuota,
            stat: cpuStat
          }
        });
      }).catch(rejectUnlessFileNotFound);
    }).catch(rejectUnlessFileNotFound);

    function rejectUnlessFileNotFound(err) {
      if (err.code === 'ENOENT') {
        resolve(null);
      } else {
        reject(err);
      }
    }
  });
}