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
const config_schema_1 = require("@kbn/config-schema");
const https_1 = require("https");
const lodash_1 = require("lodash");
const http_tools_1 = require("./http_tools");
const alphabet = 'abcdefghijklmnopqrztuvwxyz'.split('');
class BasePathProxyServer {
    constructor(log, httpConfig, devConfig) {
        this.log = log;
        this.httpConfig = httpConfig;
        this.devConfig = devConfig;
        const ONE_GIGABYTE = 1024 * 1024 * 1024;
        httpConfig.maxPayload = new config_schema_1.ByteSizeValue(ONE_GIGABYTE);
        if (!httpConfig.basePath) {
            httpConfig.basePath = `/${lodash_1.sample(alphabet, 3).join('')}`;
        }
    }
    get basePath() {
        return this.httpConfig.basePath;
    }
    get targetPort() {
        return this.devConfig.basePathProxyTargetPort;
    }
    async start(options) {
        this.log.debug('starting basepath proxy server');
        const serverOptions = http_tools_1.getServerOptions(this.httpConfig);
        this.server = http_tools_1.createServer(serverOptions);
        // Register hapi plugin that adds proxying functionality. It can be configured
        // through the route configuration object (see { handler: { proxy: ... } }).
        await this.server.register({ plugin: require('h2o2') });
        if (this.httpConfig.ssl.enabled) {
            const tlsOptions = serverOptions.tls;
            this.httpsAgent = new https_1.Agent({
                ca: tlsOptions.ca,
                cert: tlsOptions.cert,
                key: tlsOptions.key,
                passphrase: tlsOptions.passphrase,
                rejectUnauthorized: false,
            });
        }
        this.setupRoutes(options);
        await this.server.start();
        this.log.info(`basepath proxy server running at ${this.server.info.uri}${this.httpConfig.basePath}`);
    }
    async stop() {
        if (this.server === undefined) {
            return;
        }
        this.log.debug('stopping basepath proxy server');
        await this.server.stop();
        this.server = undefined;
        if (this.httpsAgent !== undefined) {
            this.httpsAgent.destroy();
            this.httpsAgent = undefined;
        }
    }
    setupRoutes({ blockUntil, shouldRedirectFromOldBasePath, }) {
        if (this.server === undefined) {
            throw new Error(`Routes cannot be set up since server is not initialized.`);
        }
        // Always redirect from root URL to the URL with basepath.
        this.server.route({
            handler: (request, responseToolkit) => {
                return responseToolkit.redirect(this.httpConfig.basePath);
            },
            method: 'GET',
            path: '/',
        });
        this.server.route({
            handler: {
                proxy: {
                    agent: this.httpsAgent,
                    host: this.server.info.host,
                    passThrough: true,
                    port: this.devConfig.basePathProxyTargetPort,
                    protocol: this.server.info.protocol,
                    xforward: true,
                },
            },
            method: '*',
            options: {
                pre: [
                    // Before we proxy request to a target port we may want to wait until some
                    // condition is met (e.g. until target listener is ready).
                    async (request, responseToolkit) => {
                        await blockUntil();
                        return responseToolkit.continue;
                    },
                ],
            },
            path: `${this.httpConfig.basePath}/{kbnPath*}`,
        });
        // It may happen that basepath has changed, but user still uses the old one,
        // so we can try to check if that's the case and just redirect user to the
        // same URL, but with valid basepath.
        this.server.route({
            handler: (request, responseToolkit) => {
                const { oldBasePath, kbnPath = '' } = request.params;
                const isGet = request.method === 'get';
                const isBasepathLike = oldBasePath.length === 3;
                return isGet && isBasepathLike && shouldRedirectFromOldBasePath(kbnPath)
                    ? responseToolkit.redirect(`${this.httpConfig.basePath}/${kbnPath}`)
                    : responseToolkit.response('Not Found').code(404);
            },
            method: '*',
            path: `/{oldBasePath}/{kbnPath*}`,
        });
    }
}
exports.BasePathProxyServer = BasePathProxyServer;
