"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const get_usage_collector_1 = require("./get_usage_collector");
function registerVisualizationsCollector(server) {
    const { usage } = server;
    const collector = usage.collectorSet.makeUsageCollector(get_usage_collector_1.getUsageCollector(server));
    usage.collectorSet.register(collector);
}
exports.registerVisualizationsCollector = registerVisualizationsCollector;
