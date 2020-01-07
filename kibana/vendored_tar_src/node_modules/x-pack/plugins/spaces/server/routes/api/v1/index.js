"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const route_pre_check_license_1 = require("../../../lib/route_pre_check_license");
const spaces_1 = require("./spaces");
function initPrivateApis(server) {
    const routePreCheckLicenseFn = route_pre_check_license_1.routePreCheckLicense(server);
    spaces_1.initPrivateSpacesApi(server, routePreCheckLicenseFn);
}
exports.initPrivateApis = initPrivateApis;
