'use strict';

var _path = require('path');

var _utils = require('../utils');

var _command = require('../cli/command');

var _command2 = _interopRequireDefault(_command);

var _path2 = require('../server/path');

var _keystore = require('../server/keystore');

var _create = require('./create');

var _list = require('./list');

var _add = require('./add');

var _remove = require('./remove');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const path = (0, _path.join)((0, _path2.getData)(), 'kibana.keystore'); /*
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

const keystore = new _keystore.Keystore(path);

const program = new _command2.default('bin/kibana-keystore');

program.version(_utils.pkg.version).description('A tool for managing settings stored in the Kibana keystore');

(0, _create.createCli)(program, keystore);
(0, _list.listCli)(program, keystore);
(0, _add.addCli)(program, keystore);
(0, _remove.removeCli)(program, keystore);

program.parse(process.argv);

if (!program.args.length) {
  program.help();
}