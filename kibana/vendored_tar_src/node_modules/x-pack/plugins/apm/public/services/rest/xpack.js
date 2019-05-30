"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const callApi_1 = require("./callApi");
async function loadLicense() {
    return callApi_1.callApi({
        pathname: `/api/xpack/v1/info`
    });
}
exports.loadLicense = loadLicense;
