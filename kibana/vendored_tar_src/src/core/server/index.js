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
const plugins_1 = require("./plugins");
var bootstrap_1 = require("./bootstrap");
exports.bootstrap = bootstrap_1.bootstrap;
const operators_1 = require("rxjs/operators");
const http_1 = require("./http");
const legacy_compat_1 = require("./legacy_compat");
class Server {
    constructor(configService, logger, env) {
        this.env = env;
        this.log = logger.get('server');
        this.http = new http_1.HttpModule(configService.atPath('server', http_1.HttpConfig), logger);
        const core = { env, configService, logger };
        this.plugins = new plugins_1.PluginsModule(core);
        this.legacy = new legacy_compat_1.LegacyCompatModule(core);
    }
    async start() {
        this.log.debug('starting server');
        // We shouldn't start http service in two cases:
        // 1. If `server.autoListen` is explicitly set to `false`.
        // 2. When the process is run as dev cluster master in which case cluster manager
        // will fork a dedicated process where http service will be started instead.
        let httpStartContract;
        const httpConfig = await this.http.config$.pipe(operators_1.first()).toPromise();
        if (!this.env.isDevClusterMaster && httpConfig.autoListen) {
            httpStartContract = await this.http.service.start();
        }
        const pluginsStartContract = await this.plugins.service.start();
        await this.legacy.service.start({
            http: httpStartContract,
            plugins: pluginsStartContract,
        });
    }
    async stop() {
        this.log.debug('stopping server');
        await this.legacy.service.stop();
        await this.plugins.service.stop();
        await this.http.service.stop();
    }
}
exports.Server = Server;
