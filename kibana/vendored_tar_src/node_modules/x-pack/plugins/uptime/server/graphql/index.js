"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const monitors_1 = require("./monitors");
const pings_1 = require("./pings");
const unsigned_int_scalar_1 = require("./unsigned_int_scalar");
var constants_1 = require("./constants");
exports.DEFAULT_GRAPHQL_PATH = constants_1.DEFAULT_GRAPHQL_PATH;
exports.resolvers = [
    pings_1.createPingsResolvers,
    unsigned_int_scalar_1.unsignedIntegerResolverFunctions,
    monitors_1.createMonitorsResolvers,
];
exports.typeDefs = [pings_1.pingsSchema, unsigned_int_scalar_1.unsignedIntegerSchema, monitors_1.monitorsSchema];
