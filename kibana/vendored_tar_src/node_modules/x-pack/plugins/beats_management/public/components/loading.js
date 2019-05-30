"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const eui_1 = require("@elastic/eui");
const React = tslib_1.__importStar(require("react"));
exports.Loading = () => (React.createElement(eui_1.EuiFlexGroup, { justifyContent: "spaceAround" },
    React.createElement(eui_1.EuiFlexItem, { grow: false },
        React.createElement(eui_1.EuiLoadingSpinner, { size: "xl" }))));
