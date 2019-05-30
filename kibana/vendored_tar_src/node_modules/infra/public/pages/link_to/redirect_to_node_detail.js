"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const react_1 = tslib_1.__importDefault(require("react"));
const react_router_dom_1 = require("react-router-dom");
const with_metrics_time_1 = require("../../containers/metrics/with_metrics_time");
const query_params_1 = require("./query_params");
exports.RedirectToNodeDetail = ({ match: { params: { nodeId, nodeType }, }, location, }) => {
    const searchString = with_metrics_time_1.replaceMetricTimeInQueryString(query_params_1.getFromFromLocation(location), query_params_1.getToFromLocation(location))('');
    return react_1.default.createElement(react_router_dom_1.Redirect, { to: `/metrics/${nodeType}/${nodeId}?${searchString}` });
};
exports.getNodeDetailUrl = ({ nodeType, nodeId, to, from, }) => {
    const args = to && from ? `?to=${to}&from=${from}` : '';
    return `#/link-to/${nodeType}-detail/${nodeId}${args}`;
};
