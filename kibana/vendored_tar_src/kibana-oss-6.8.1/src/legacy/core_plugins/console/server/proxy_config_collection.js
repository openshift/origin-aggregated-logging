'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.ProxyConfigCollection = undefined;

var _lodash = require('lodash');

var _proxy_config = require('./proxy_config');

var _url = require('url');

class ProxyConfigCollection {
  constructor(configs = []) {
    this.configs = configs.map(settings => new _proxy_config.ProxyConfig(settings));
  }

  configForUri(uri) {
    const parsedUri = (0, _url.parse)(uri);
    const settings = this.configs.map(config => config.getForParsedUri(parsedUri));
    return (0, _lodash.defaultsDeep)({}, ...settings);
  }
}
exports.ProxyConfigCollection = ProxyConfigCollection; /*
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