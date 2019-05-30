"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const lodash_1 = require("lodash");
const react_1 = tslib_1.__importDefault(require("react"));
const react_redux_request_1 = require("react-redux-request");
const reselect_1 = require("reselect");
const transaction_groups_1 = require("../../services/rest/apm/transaction_groups");
const chartSelectors_1 = require("../selectors/chartSelectors");
const urlParams_1 = require("../urlParams");
const ID = 'transactionOverviewCharts';
const INITIAL_DATA = {
    apmTimeseries: {
        totalHits: 0,
        responseTimes: {
            avg: [],
            p95: [],
            p99: []
        },
        tpmBuckets: [],
        overallAvgDuration: undefined
    },
    anomalyTimeseries: undefined
};
const selectChartData = (state) => state.reactReduxRequest[ID];
exports.getTransactionOverviewCharts = reselect_1.createSelector([urlParams_1.getUrlParams, selectChartData], (urlParams, overviewCharts = {}) => {
    return {
        ...overviewCharts,
        data: chartSelectors_1.getTransactionCharts(urlParams, overviewCharts.data || INITIAL_DATA)
    };
});
exports.selectHasMLJob = reselect_1.createSelector([selectChartData], chartData => lodash_1.get(chartData, 'data.anomalyTimeseries') !== undefined);
function TransactionOverviewChartsRequest({ urlParams, render }) {
    const { serviceName, start, end, transactionType, kuery } = urlParams;
    if (!(serviceName && start && end)) {
        return null;
    }
    return (react_1.default.createElement(react_redux_request_1.Request, { id: ID, fn: transaction_groups_1.loadOverviewCharts, args: [{ serviceName, start, end, transactionType, kuery }], selector: exports.getTransactionOverviewCharts, render: render }));
}
exports.TransactionOverviewChartsRequest = TransactionOverviewChartsRequest;
// Ignores transaction type from urlParams and requests charts
// for ALL transaction types within this service
function TransactionOverviewChartsRequestForAllTypes({ urlParams, render }) {
    const { serviceName, start, end, kuery } = urlParams;
    if (!(serviceName && start && end)) {
        return null;
    }
    return (react_1.default.createElement(react_redux_request_1.Request, { id: ID, fn: transaction_groups_1.loadOverviewChartsForAllTypes, args: [{ serviceName, start, end, kuery }], selector: exports.getTransactionOverviewCharts, render: render }));
}
exports.TransactionOverviewChartsRequestForAllTypes = TransactionOverviewChartsRequestForAllTypes;
