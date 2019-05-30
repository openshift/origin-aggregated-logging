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
const services_1 = require("../../services/rest/apm/services");
const helpers_1 = require("./helpers");
const ID = 'serviceList';
const INITIAL_DATA = [];
const withInitialData = helpers_1.createInitialDataSelector(INITIAL_DATA);
function getServiceList(state) {
    return withInitialData(state.reactReduxRequest[ID]);
}
exports.getServiceList = getServiceList;
function ServiceListRequest({ urlParams, render }) {
    const { start, end, kuery } = urlParams;
    if (!(start && end)) {
        return null;
    }
    return (react_1.default.createElement(react_redux_request_1.Request, { id: ID, fn: services_1.loadServiceList, args: [{ start, end, kuery }], selector: getServiceList, render: render }));
}
exports.ServiceListRequest = ServiceListRequest;
