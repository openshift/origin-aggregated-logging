"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const callApi_1 = require("../callApi");
const apm_1 = require("./apm");
async function loadMetricsChartDataForService({ serviceName, start, end, kuery }) {
    return callApi_1.callApi({
        pathname: `/api/apm/services/${serviceName}/metrics/charts`,
        query: {
            start,
            end,
            esFilterQuery: await apm_1.getEncodedEsQuery(kuery)
        }
    });
}
exports.loadMetricsChartDataForService = loadMetricsChartDataForService;
