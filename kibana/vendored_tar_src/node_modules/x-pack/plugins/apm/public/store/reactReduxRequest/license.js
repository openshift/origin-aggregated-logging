"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
const react_1 = tslib_1.__importDefault(require("react"));
const react_redux_request_1 = require("react-redux-request");
const xpack_1 = require("../../services/rest/xpack");
const helpers_1 = require("./helpers");
const ID = 'license';
const INITIAL_DATA = {
    features: {
        watcher: { is_available: false },
        ml: { is_available: false }
    },
    license: { is_active: false }
};
const withInitialData = helpers_1.createInitialDataSelector(INITIAL_DATA);
function getLicense(state) {
    return withInitialData(state.reactReduxRequest[ID]);
}
exports.getLicense = getLicense;
function LicenceRequest({ render }) {
    return (react_1.default.createElement(react_redux_request_1.Request, { id: ID, fn: xpack_1.loadLicense, selector: getLicense, render: render }));
}
exports.LicenceRequest = LicenceRequest;
