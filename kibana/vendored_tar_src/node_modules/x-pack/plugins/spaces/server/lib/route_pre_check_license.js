"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const boom_1 = tslib_1.__importDefault(require("boom"));
function routePreCheckLicense(server) {
    const xpackMainPlugin = server.plugins.xpack_main;
    const pluginId = 'spaces';
    return function forbidApiAccess(request) {
        const licenseCheckResults = xpackMainPlugin.info.feature(pluginId).getLicenseCheckResults();
        if (!licenseCheckResults.showSpaces) {
            return boom_1.default.forbidden(licenseCheckResults.linksMessage);
        }
        else {
            return '';
        }
    };
}
exports.routePreCheckLicense = routePreCheckLicense;
