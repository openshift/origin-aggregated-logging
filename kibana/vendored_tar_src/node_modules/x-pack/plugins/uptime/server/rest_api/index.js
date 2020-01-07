"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const auth_1 = require("./auth");
const pings_1 = require("./pings");
var create_route_with_auth_1 = require("./create_route_with_auth");
exports.createRouteWithAuth = create_route_with_auth_1.createRouteWithAuth;
exports.restApiRoutes = [auth_1.createIsValidRoute, pings_1.createGetAllRoute];
