"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const route_pre_check_license_1 = require("../../../lib/route_pre_check_license");
const delete_1 = require("./delete");
const get_1 = require("./get");
const post_1 = require("./post");
const put_1 = require("./put");
function initPublicSpacesApi(server) {
    const routePreCheckLicenseFn = route_pre_check_license_1.routePreCheckLicense(server);
    delete_1.initDeleteSpacesApi(server, routePreCheckLicenseFn);
    get_1.initGetSpacesApi(server, routePreCheckLicenseFn);
    post_1.initPostSpacesApi(server, routePreCheckLicenseFn);
    put_1.initPutSpacesApi(server, routePreCheckLicenseFn);
}
exports.initPublicSpacesApi = initPublicSpacesApi;
