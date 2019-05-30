"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const lodash_1 = require("lodash");
class UMMemoryAuthAdapter {
    constructor(xpack) {
        this.xpack = xpack;
        this.getLicenseType = () => lodash_1.get(this.xpack, 'info.license.type', null);
        this.licenseIsActive = () => this.xpack.info.license.isActive;
        this.xpack = xpack;
    }
}
exports.UMMemoryAuthAdapter = UMMemoryAuthAdapter;
