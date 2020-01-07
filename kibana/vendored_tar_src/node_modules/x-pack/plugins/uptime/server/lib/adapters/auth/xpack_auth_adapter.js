"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const constants_1 = require("../../../../common/constants");
// look at index-management for guidance, subscribe to licensecheckerresultsgenerator
// then check the license status
class UMXPackAuthAdapter {
    constructor(xpack) {
        this.xpack = xpack;
        this.getLicenseType = () => this.xpackLicenseStatus.licenseType || null;
        this.licenseIsActive = () => this.xpackLicenseStatus.isActive || false;
        this.registerLicenseCheck = () => this.xpack.info.feature(constants_1.PLUGIN.ID).registerLicenseCheckResultsGenerator(this.updateLicenseInfo);
        this.updateLicenseInfo = (xpackLicenseStatus) => {
            this.xpackLicenseStatus = {
                isActive: xpackLicenseStatus.license.isActive(),
                licenseType: xpackLicenseStatus.license.getType(),
            };
        };
        this.xpack = xpack;
        this.xpackLicenseStatus = {
            isActive: null,
            licenseType: null,
        };
        this.xpack.status.once('green', this.registerLicenseCheck);
    }
}
exports.UMXPackAuthAdapter = UMXPackAuthAdapter;
