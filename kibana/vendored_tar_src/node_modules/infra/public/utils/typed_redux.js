"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const redux_1 = require("redux");
exports.globalizeSelector = (globalizer, selector) => (globalState) => selector(globalizer(globalState));
exports.globalizeSelectors = (globalizer, selectors) => {
    const globalSelectors = {};
    for (const s in selectors) {
        if (selectors.hasOwnProperty(s)) {
            globalSelectors[s] = exports.globalizeSelector(globalizer, selectors[s]);
        }
    }
    return globalSelectors;
};
exports.bindPlainActionCreators = (actionCreators) => (dispatch) => redux_1.bindActionCreators(actionCreators, dispatch);
