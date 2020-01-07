"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const eui_1 = require("@elastic/eui");
const react_1 = tslib_1.__importDefault(require("react"));
function ImpactBar({ value, max = 100, ...rest }) {
    return (react_1.default.createElement(eui_1.EuiProgress, Object.assign({ size: "l", value: value, max: max, color: "primary" }, rest)));
}
exports.ImpactBar = ImpactBar;
