"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const get_anomaly_data_1 = require("./get_anomaly_data");
const get_timeseries_data_1 = require("./get_timeseries_data");
function getDates(apmTimeseries) {
    return apmTimeseries.responseTimes.avg.map(p => p.x);
}
async function getChartsData(options) {
    const apmTimeseries = await get_timeseries_data_1.getApmTimeseriesData(options);
    const anomalyTimeseries = await get_anomaly_data_1.getAnomalySeries({
        ...options,
        timeSeriesDates: getDates(apmTimeseries)
    });
    return {
        apmTimeseries,
        anomalyTimeseries
    };
}
exports.getChartsData = getChartsData;
