"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const adapter_types_1 = require("./adapter_types");
class HapiBackendFrameworkAdapter {
    constructor(settings = {
        encryptionKey: 'something_who_cares',
        enrollmentTokensTtlInSeconds: 10 * 60,
    }, hapiServer, license = 'trial', securityEnabled = true, licenseActive = true) {
        this.info = null;
        this.internalUser = adapter_types_1.internalUser;
        this.server = hapiServer;
        this.settings = settings;
        const now = new Date();
        this.info = {
            kibana: {
                version: 'unknown',
            },
            license: {
                type: license,
                expired: !licenseActive,
                expiry_date_in_millis: new Date(now.getFullYear(), now.getMonth() + 1, 1).getTime(),
            },
            security: {
                enabled: securityEnabled,
                available: securityEnabled,
            },
            watcher: {
                enabled: true,
                available: true,
            },
        };
    }
    log(text) {
        this.server.log(text);
    }
    on(event, cb) {
        cb();
    }
    getSetting(settingPath) {
        switch (settingPath) {
            case 'xpack.beats.enrollmentTokensTtlInSeconds':
                return this.settings.enrollmentTokensTtlInSeconds;
            case 'xpack.beats.encryptionKey':
                return this.settings.encryptionKey;
        }
    }
    exposeStaticDir(urlPath, dir) {
        if (!this.server) {
            throw new Error('Must pass a hapi server into the adapter to use exposeStaticDir');
        }
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
        if (!this.server) {
            throw new Error('Must pass a hapi server into the adapter to use registerRoute');
        }
        const wrappedHandler = (licenseRequired) => (request, h) => {
            return route.handler(this.wrapRequest(request), h);
        };
        this.server.route({
            handler: wrappedHandler(route.licenseRequired || []),
            method: route.method,
            path: route.path,
            config: {
                ...route.config,
                auth: false,
            },
        });
    }
    async injectRequstForTesting({ method, url, headers, payload }) {
        return await this.server.inject({ method, url, headers, payload });
    }
    wrapRequest(req) {
        const { params, payload, query, headers, info } = req;
        const isAuthenticated = headers.authorization != null;
        return {
            user: isAuthenticated
                ? {
                    kind: 'authenticated',
                    [adapter_types_1.internalAuthData]: headers,
                    username: 'elastic',
                    roles: ['superuser'],
                    full_name: null,
                    email: null,
                    enabled: true,
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
}
exports.HapiBackendFrameworkAdapter = HapiBackendFrameworkAdapter;
