"use strict";
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
Object.defineProperty(exports, "__esModule", { value: true });
const http_config_1 = require("./http_config");
exports.HttpConfig = http_config_1.HttpConfig;
const http_service_1 = require("./http_service");
exports.HttpService = http_service_1.HttpService;
const router_1 = require("./router");
var router_2 = require("./router");
exports.Router = router_2.Router;
exports.KibanaRequest = router_2.KibanaRequest;
var base_path_proxy_server_1 = require("./base_path_proxy_server");
exports.BasePathProxyServer = base_path_proxy_server_1.BasePathProxyServer;
class HttpModule {
    constructor(config$, logger) {
        this.config$ = config$;
        this.service = new http_service_1.HttpService(this.config$, logger);
        const router = new router_1.Router('/core');
        router.get({ path: '/', validate: false }, async (req, res) => res.ok({ version: '0.0.1' }));
        this.service.registerRouter(router);
    }
}
exports.HttpModule = HttpModule;
