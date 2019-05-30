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
const error_groups_1 = require("../../services/rest/apm/error_groups");
// @ts-ignore
const helpers_1 = require("./helpers");
const ID = 'errorDistribution';
const INITIAL_DATA = {
    buckets: [],
    totalHits: 0,
    bucketSize: 0
};
const withInitialData = helpers_1.createInitialDataSelector(INITIAL_DATA);
function getErrorDistribution(state) {
    return withInitialData(state.reactReduxRequest[ID]);
}
exports.getErrorDistribution = getErrorDistribution;
function ErrorDistributionRequest({ urlParams, render }) {
    const { serviceName, start, end, errorGroupId, kuery } = urlParams;
    if (!(serviceName && start && end)) {
        return null;
    }
    return (react_1.default.createElement(react_redux_request_1.Request, { id: ID, fn: error_groups_1.loadErrorDistribution, args: [{ serviceName, start, end, errorGroupId, kuery }], selector: getErrorDistribution, render: render }));
}
exports.ErrorDistributionRequest = ErrorDistributionRequest;
