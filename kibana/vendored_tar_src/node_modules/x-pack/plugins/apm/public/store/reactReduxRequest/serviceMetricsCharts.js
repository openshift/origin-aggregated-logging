"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const react_1 = tslib_1.__importDefault(require("react"));
const react_redux_request_1 = require("react-redux-request");
const reselect_1 = require("reselect");
const metrics_1 = require("x-pack/plugins/apm/public/services/rest/apm/metrics");
const chartSelectors_1 = require("../selectors/chartSelectors");
const urlParams_1 = require("../urlParams");
const helpers_1 = require("./helpers");
const ID = 'metricsChartData';
const INITIAL_DATA = {
    memory: {
        series: {
            memoryUsedAvg: [],
            memoryUsedMax: []
        },
        overallValues: {
            memoryUsedAvg: null,
            memoryUsedMax: null
        },
        totalHits: 0
    },
    cpu: {
        series: {
            systemCPUAverage: [],
            systemCPUMax: [],
            processCPUAverage: [],
            processCPUMax: []
        },
        overallValues: {
            systemCPUAverage: null,
            systemCPUMax: null,
            processCPUAverage: null,
            processCPUMax: null
        },
        totalHits: 0
    }
};
const withInitialData = helpers_1.createInitialDataSelector(INITIAL_DATA);
const selectMetricsChartData = state => withInitialData(state.reactReduxRequest[ID]);
exports.selectTransformedMetricsChartData = reselect_1.createSelector([urlParams_1.getUrlParams, selectMetricsChartData], (urlParams, response) => ({
    ...response,
    data: {
        ...response.data,
        memory: chartSelectors_1.getMemorySeries(urlParams, response.data.memory),
        cpu: chartSelectors_1.getCPUSeries(response.data.cpu)
    }
}));
function MetricsChartDataRequest({ urlParams, render }) {
    const { serviceName, start, end } = urlParams;
    if (!(serviceName && start && end)) {
        return null;
    }
    return (react_1.default.createElement(react_redux_request_1.Request, { id: ID, fn: metrics_1.loadMetricsChartDataForService, args: [urlParams], selector: exports.selectTransformedMetricsChartData, render: render }));
}
exports.MetricsChartDataRequest = MetricsChartDataRequest;
