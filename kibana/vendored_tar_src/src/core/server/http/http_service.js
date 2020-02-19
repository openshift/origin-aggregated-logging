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
const operators_1 = require("rxjs/operators");
const http_server_1 = require("./http_server");
const https_redirect_server_1 = require("./https_redirect_server");
/** @internal */
class HttpService {
    constructor(config$, logger) {
        this.config$ = config$;
        this.log = logger.get('http');
        this.httpServer = new http_server_1.HttpServer(logger.get('http', 'server'));
        this.httpsRedirectServer = new https_redirect_server_1.HttpsRedirectServer(logger.get('http', 'redirect', 'server'));
    }
    async start() {
        this.configSubscription = this.config$.subscribe(() => {
            if (this.httpServer.isListening()) {
                // If the server is already running we can't make any config changes
                // to it, so we warn and don't allow the config to pass through.
                this.log.warn('Received new HTTP config after server was started. ' + 'Config will **not** be applied.');
            }
        });
        const config = await this.config$.pipe(operators_1.first()).toPromise();
        // If a redirect port is specified, we start an HTTP server at this port and
        // redirect all requests to the SSL port.
        if (config.ssl.enabled && config.ssl.redirectHttpFromPort !== undefined) {
            await this.httpsRedirectServer.start(config);
        }
        return await this.httpServer.start(config);
    }
    async stop() {
        if (this.configSubscription === undefined) {
            return;
        }
        this.configSubscription.unsubscribe();
        this.configSubscription = undefined;
        await this.httpServer.stop();
        await this.httpsRedirectServer.stop();
    }
    registerRouter(router) {
        if (this.httpServer.isListening()) {
            // If the server is already running we can't make any config changes
            // to it, so we warn and don't allow the config to pass through.
            // TODO Should we throw instead?
            this.log.error(`Received new router [${router.path}] after server was started. ` +
                'Router will **not** be applied.');
        }
        else {
            this.log.debug(`registering route handler for [${router.path}]`);
            this.httpServer.registerRouter(router);
        }
    }
}
exports.HttpService = HttpService;
