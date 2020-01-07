"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const boom_1 = tslib_1.__importDefault(require("boom"));
const lodash_1 = require("lodash");
const supportedLicenses = ['standard', 'gold', 'platinum', 'trial'];
class UMAuthDomain {
    constructor(adapter, libs) {
        this.adapter = adapter;
        this.adapter = adapter;
    }
    requestIsValid(request) {
        const license = this.adapter.getLicenseType();
        if (license === null) {
            throw boom_1.default.badRequest('Missing license information');
        }
        if (!supportedLicenses.some(licenseType => licenseType === license)) {
            throw boom_1.default.forbidden('License not supported');
        }
        if (this.adapter.licenseIsActive() === false) {
            throw boom_1.default.forbidden('License not active');
        }
        return this.checkRequest(request);
    }
    checkRequest(request) {
        const authenticated = lodash_1.get(request, 'auth.isAuthenticated', null);
        if (authenticated === null) {
            throw boom_1.default.forbidden('Missing authentication');
        }
        return authenticated;
    }
}
exports.UMAuthDomain = UMAuthDomain;
