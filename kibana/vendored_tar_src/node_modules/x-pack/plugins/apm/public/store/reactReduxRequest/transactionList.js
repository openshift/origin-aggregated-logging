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
const helpers_1 = require("./helpers");
const ID = 'transactionList';
const INITIAL_DATA = [];
const withInitialData = helpers_1.createInitialDataSelector(INITIAL_DATA);
const getRelativeImpact = (impact, impactMin, impactMax) => Math.max(((impact - impactMin) / Math.max(impactMax - impactMin, 1)) * 100, 1);
function getWithRelativeImpact(items) {
    const impacts = items.map(({ impact }) => impact);
    const impactMin = Math.min(...impacts);
    const impactMax = Math.max(...impacts);
    return items.map(item => {
        return {
            ...item,
            impactRelative: getRelativeImpact(item.impact, impactMin, impactMax)
        };
    });
}
exports.getTransactionList = reselect_1.createSelector((state) => withInitialData(state.reactReduxRequest[ID]), transactionList => {
    return {
        ...transactionList,
        data: getWithRelativeImpact(transactionList.data)
    };
});
function TransactionListRequest({ urlParams, render }) {
    const { serviceName, start, end, transactionType, kuery } = urlParams;
    if (!(serviceName && start && end)) {
        return null;
    }
    return (react_1.default.createElement(react_redux_request_1.Request, { id: ID, fn: transaction_groups_1.loadTransactionList, args: [
            {
                serviceName,
                start,
                end,
                transactionType,
                kuery
            }
        ], selector: exports.getTransactionList, render: render }));
}
exports.TransactionListRequest = TransactionListRequest;
