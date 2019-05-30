"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const get_cpu_chart_data_1 = require("./get_cpu_chart_data");
const get_memory_chart_data_1 = require("./get_memory_chart_data");
async function getAllMetricsChartData(args) {
    const [memoryChartData, cpuChartData] = await Promise.all([
        get_memory_chart_data_1.getMemoryChartData(args),
        get_cpu_chart_data_1.getCPUChartData(args)
    ]);
    return {
        memory: memoryChartData,
        cpu: cpuChartData
    };
}
exports.getAllMetricsChartData = getAllMetricsChartData;
