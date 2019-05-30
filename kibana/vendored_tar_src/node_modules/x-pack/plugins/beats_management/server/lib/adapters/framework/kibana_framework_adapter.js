"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const PathReporter_1 = require("io-ts/lib/PathReporter");
const lodash_1 = require("lodash");
// @ts-ignore
const mirror_plugin_status_1 = require("../../../../../../server/lib/mirror_plugin_status");
const adapter_types_1 = require("./adapter_types");
class KibanaBackendFrameworkAdapter {
    constructor(PLUGIN_ID, server, CONFIG_PREFIX) {
        this.PLUGIN_ID = PLUGIN_ID;
        this.server = server;
        this.CONFIG_PREFIX = CONFIG_PREFIX;
        this.internalUser = adapter_types_1.internalUser;
        this.info = null;
        this.xpackInfoWasUpdatedHandler = (xpackInfo) => {
            let xpackInfoUnpacked;
            // If, for some reason, we cannot get the license information
            // from Elasticsearch, assume worst case and disable
            if (!xpackInfo || !xpackInfo.isAvailable()) {
                this.info = null;
                return;
            }
            try {
                xpackInfoUnpacked = {
                    kibana: {
                        version: lodash_1.get(this.server, 'plugins.kibana.status.plugin.version', 'unknown'),
                    },
                    license: {
                        type: xpackInfo.license.getType(),
                        expired: !xpackInfo.license.isActive(),
                        expiry_date_in_millis: xpackInfo.license.getExpiryDateInMillis() !== undefined
                            ? xpackInfo.license.getExpiryDateInMillis()
                            : -1,
                    },
                    security: {
                        enabled: !!xpackInfo.feature('security') && xpackInfo.feature('security').isEnabled(),
                        available: !!xpackInfo.feature('security'),
                    },
                    watcher: {
                        enabled: !!xpackInfo.feature('watcher') && xpackInfo.feature('watcher').isEnabled(),
                        available: !!xpackInfo.feature('watcher'),
                    },
                };
            }
            catch (e) {
                this.server.log(`Error accessing required xPackInfo in ${this.PLUGIN_ID} Kibana adapter`);
                throw e;
            }
            const assertData = adapter_types_1.RuntimeFrameworkInfo.decode(xpackInfoUnpacked);
            if (assertData.isLeft()) {
                throw new Error(`Error parsing xpack info in ${this.PLUGIN_ID},   ${PathReporter_1.PathReporter.report(assertData)[0]}`);
            }
            this.info = xpackInfoUnpacked;
            return {
                security: xpackInfoUnpacked.security,
                settings: this.getSetting(this.CONFIG_PREFIX || this.PLUGIN_ID),
            };
        };
        const xpackMainPlugin = this.server.plugins.xpack_main;
        const thisPlugin = this.server.plugins.beats_management;
        mirror_plugin_status_1.mirrorPluginStatus(xpackMainPlugin, thisPlugin);
        xpackMainPlugin.status.on('green', () => {
            this.xpackInfoWasUpdatedHandler(xpackMainPlugin.info);
            // Register a function that is called whenever the xpack info changes,
            // to re-compute the license check results for this plugin
            xpackMainPlugin.info
                .feature(this.PLUGIN_ID)
                .registerLicenseCheckResultsGenerator(this.xpackInfoWasUpdatedHandler);
        });
    }
    on(event, cb) {
        switch (event) {
            case 'xpack.status.green':
                this.server.plugins.xpack_main.status.on('green', cb);
            case 'elasticsearch.status.green':
                this.server.plugins.elasticsearch.status.on('green', cb);
        }
    }
    getSetting(settingPath) {
        return this.server.config().get(settingPath);
    }
    log(text) {
        this.server.log(text);
    }
    exposeStaticDir(urlPath, dir) {
        this.server.route({
            handler: {
                directory: {
                    path: dir,
                },
            },
            method: 'GET',
            path: urlPath,
        });
    }
    registerRoute(route) {
        this.server.route({
            handler: async (request, h) => {
                // Note, RuntimeKibanaServerRequest is avalaible to validate request, and its type *is* KibanaServerRequest
                // but is not used here for perf reasons. It's value here is not high enough...
                return await route.handler(await this.wrapRequest(request), h);
            },
            method: route.method,
            path: route.path,
            config: route.config,
        });
    }
    async wrapRequest(req) {
        const { params, payload, query, headers, info } = req;
        let isAuthenticated = headers.authorization != null;
        let user;
        if (isAuthenticated) {
            user = await this.getUser(req);
            if (!user) {
                isAuthenticated = false;
            }
        }
        return {
            user: isAuthenticated && user
                ? {
                    kind: 'authenticated',
                    [adapter_types_1.internalAuthData]: headers,
                    ...user,
                }
                : {
                    kind: 'unauthenticated',
                },
            headers,
            info,
            params,
            payload,
            query,
        };
    }
    async getUser(request) {
        let user;
        try {
            user = await this.server.plugins.security.getUser(request);
        }
        catch (e) {
            return null;
        }
        if (user === null) {
            return null;
        }
        const assertKibanaUser = adapter_types_1.RuntimeKibanaUser.decode(user);
        if (assertKibanaUser.isLeft()) {
            throw new Error(`Error parsing user info in ${this.PLUGIN_ID},   ${PathReporter_1.PathReporter.report(assertKibanaUser)[0]}`);
        }
        return user;
    }
}
exports.KibanaBackendFrameworkAdapter = KibanaBackendFrameworkAdapter;
