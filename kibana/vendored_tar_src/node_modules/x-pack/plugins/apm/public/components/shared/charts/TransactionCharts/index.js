"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const react_redux_1 = require("react-redux");
const transactionOverviewCharts_1 = require("x-pack/plugins/apm/public/store/reactReduxRequest/transactionOverviewCharts");
const license_1 = require("x-pack/plugins/apm/public/store/selectors/license");
const view_1 = require("./view");
const mapStateToProps = (state) => ({
    mlAvailable: license_1.selectIsMLAvailable(state),
    hasMLJob: transactionOverviewCharts_1.selectHasMLJob(state)
});
exports.TransactionCharts = react_redux_1.connect(mapStateToProps)(view_1.TransactionChartsView);
