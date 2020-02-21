'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getData = exports.getConfig = undefined;

var _fs = require('fs');

var _lodash = require('lodash');

var _utils = require('../../utils');

const CONFIG_PATHS = [process.env.CONFIG_PATH, (0, _utils.fromRoot)('config/kibana.yml'), '/etc/kibana/kibana.yml'].filter(Boolean); /*
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

const DATA_PATHS = [process.env.DATA_PATH, (0, _utils.fromRoot)('data'), '/var/lib/kibana'].filter(Boolean);

function findFile(paths) {
  const availablePath = (0, _lodash.find)(paths, configPath => {
    try {
      (0, _fs.accessSync)(configPath, _fs.R_OK);
      return true;
    } catch (e) {
      //Check the next path
    }
  });
  return availablePath || paths[0];
}

const getConfig = exports.getConfig = () => findFile(CONFIG_PATHS);
const getData = exports.getData = () => findFile(DATA_PATHS);