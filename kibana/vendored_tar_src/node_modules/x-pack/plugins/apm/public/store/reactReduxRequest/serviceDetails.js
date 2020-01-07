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
const services_1 = require("../../services/rest/apm/services");
const helpers_1 = require("./helpers");
const ID = 'serviceDetails';
const INITIAL_DATA = { types: [] };
const withInitialData = helpers_1.createInitialDataSelector(INITIAL_DATA);
function getServiceDetails(state) {
    return withInitialData(state.reactReduxRequest[ID]);
}
exports.getServiceDetails = getServiceDetails;
function getDefaultTransactionType(state) {
    const types = lodash_1.get(state.reactReduxRequest[ID], 'data.types');
    return lodash_1.first(types);
}
exports.getDefaultTransactionType = getDefaultTransactionType;
function ServiceDetailsRequest({ urlParams, render }) {
    const { serviceName, start, end, kuery } = urlParams;
    if (!(serviceName && start && end)) {
        return null;
    }
    return (react_1.default.createElement(react_redux_request_1.Request, { id: ID, fn: services_1.loadServiceDetails, args: [{ serviceName, start, end, kuery }], selector: getServiceDetails, render: render }));
}
exports.ServiceDetailsRequest = ServiceDetailsRequest;
