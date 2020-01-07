"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const react_redux_request_1 = require("react-redux-request");
const redux_1 = require("redux");
// @ts-ignore
const location_1 = tslib_1.__importDefault(require("./location"));
const urlParams_1 = require("./urlParams");
exports.rootReducer = redux_1.combineReducers({
    location: location_1.default,
    urlParams: urlParams_1.urlParamsReducer,
    reactReduxRequest: react_redux_request_1.reducer
});
