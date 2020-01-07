"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const register_usage_collector_1 = require("./visualizations/register_usage_collector");
function registerCollectors(server) {
    register_usage_collector_1.registerVisualizationsCollector(server);
}
exports.registerCollectors = registerCollectors;
