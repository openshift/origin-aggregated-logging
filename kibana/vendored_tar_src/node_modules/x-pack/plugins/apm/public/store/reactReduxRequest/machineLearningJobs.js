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
const ml_1 = require("../../services/rest/ml");
const helpers_1 = require("./helpers");
const INITIAL_DATA = { count: 0, jobs: [] };
const withInitialData = helpers_1.createInitialDataSelector(INITIAL_DATA);
const ID = 'MLJobs';
function selectMlJobs(state) {
    return withInitialData(state.reactReduxRequest[ID]);
}
function MLJobsRequest({ serviceName, transactionType = '*', render }) {
    return (react_1.default.createElement(react_redux_request_1.Request, { id: ID, fn: ml_1.getMLJob, args: [{ serviceName, transactionType }], render: render, selector: selectMlJobs }));
}
exports.MLJobsRequest = MLJobsRequest;
