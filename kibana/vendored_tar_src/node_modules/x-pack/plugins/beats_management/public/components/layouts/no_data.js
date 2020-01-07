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
const react_router_dom_1 = require("react-router-dom");
exports.NoDataLayout = react_router_dom_1.withRouter(({ actionSection, title, modalClosePath, children, history }) => {
    return (react_1.default.createElement(eui_1.EuiFlexGroup, { justifyContent: "spaceAround" },
        react_1.default.createElement(eui_1.EuiFlexItem, { grow: false },
            react_1.default.createElement(eui_1.EuiPageContent, null,
                react_1.default.createElement(eui_1.EuiEmptyPrompt, { iconType: "logoBeats", title: react_1.default.createElement("h2", null, title), body: children, actions: actionSection })))));
});
