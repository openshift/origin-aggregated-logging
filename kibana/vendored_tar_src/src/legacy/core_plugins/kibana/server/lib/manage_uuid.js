'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _uuid = require('uuid');

var _uuid2 = _interopRequireDefault(_uuid);

var _bluebird = require('bluebird');

var _bluebird2 = _interopRequireDefault(_bluebird);

var _path = require('path');

var _fs = require('fs');

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

const FILE_ENCODING = 'utf8';

exports.default = async function manageUuid(server) {
  const config = server.config();
  const fileName = 'uuid';
  const uuidFile = (0, _path.join)(config.get('path.data'), fileName);

  async function detectUuid() {
    const readFile = _bluebird2.default.promisify(_fs.readFile);
    try {
      const result = await readFile(uuidFile);
      return result.toString(FILE_ENCODING);
    } catch (err) {
      if (err.code === 'ENOENT') {
        // non-existent uuid file is ok
        return false;
      }
      server.log(['error', 'read-uuid'], err);
      // Note: this will most likely be logged as an Unhandled Rejection
      throw err;
    }
  }

  async function writeUuid(uuid) {
    const writeFile = _bluebird2.default.promisify(_fs.writeFile);
    try {
      return await writeFile(uuidFile, uuid, { encoding: FILE_ENCODING });
    } catch (err) {
      server.log(['error', 'write-uuid'], err);
      // Note: this will most likely be logged as an Unhandled Rejection
      throw err;
    }
  }

  // detect if uuid exists already from before a restart
  const logToServer = msg => server.log(['server', 'uuid', fileName], msg);
  const dataFileUuid = await detectUuid();
  let serverConfigUuid = config.get('server.uuid'); // check if already set in config

  if (dataFileUuid) {
    // data uuid found
    if (serverConfigUuid === dataFileUuid) {
      // config uuid exists, data uuid exists and matches
      logToServer(`Kibana instance UUID: ${dataFileUuid}`);
      return;
    }

    if (!serverConfigUuid) {
      // config uuid missing, data uuid exists
      serverConfigUuid = dataFileUuid;
      logToServer(`Resuming persistent Kibana instance UUID: ${serverConfigUuid}`);
      config.set('server.uuid', serverConfigUuid);
      return;
    }

    if (serverConfigUuid !== dataFileUuid) {
      // config uuid exists, data uuid exists but mismatches
      logToServer(`Updating Kibana instance UUID to: ${serverConfigUuid} (was: ${dataFileUuid})`);
      return writeUuid(serverConfigUuid);
    }
  }

  // data uuid missing

  if (!serverConfigUuid) {
    // config uuid missing
    serverConfigUuid = _uuid2.default.v4();
    config.set('server.uuid', serverConfigUuid);
  }

  logToServer(`Setting new Kibana instance UUID: ${serverConfigUuid}`);
  return writeUuid(serverConfigUuid);
};

module.exports = exports['default'];