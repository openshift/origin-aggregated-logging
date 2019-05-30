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
const transaction_groups_1 = require("../../services/rest/apm/transaction_groups");
const chartSelectors_1 = require("../selectors/chartSelectors");
const urlParams_1 = require("../urlParams");
const ID = 'transactionDetailsCharts';
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
exports.getTransactionDetailsCharts = reselect_1.createSelector(urlParams_1.getUrlParams, (state) => state.reactReduxRequest[ID], (urlParams, detailCharts = {}) => {
    return {
        ...detailCharts,
        data: chartSelectors_1.getTransactionCharts(urlParams, detailCharts.data || INITIAL_DATA)
    };
});
function TransactionDetailsChartsRequest({ urlParams, render }) {
    const { serviceName, start, end, transactionType, transactionName, kuery } = urlParams;
    if (!(serviceName && start && end && transactionType && transactionName)) {
        return null;
    }
    return (react_1.default.createElement(react_redux_request_1.Request, { id: ID, fn: transaction_groups_1.loadDetailsCharts, args: [
            { serviceName, start, end, transactionType, transactionName, kuery }
        ], selector: exports.getTransactionDetailsCharts, render: render }));
}
exports.TransactionDetailsChartsRequest = TransactionDetailsChartsRequest;
