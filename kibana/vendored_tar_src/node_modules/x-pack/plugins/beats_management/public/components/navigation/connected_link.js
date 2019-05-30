"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
const react_1 = tslib_1.__importDefault(require("react"));
const eui_1 = require("@elastic/eui");
const react_router_dom_1 = require("react-router-dom");
function ConnectedLinkComponent({ location, path, query, disabled, children, ...props }) {
    if (disabled) {
        return react_1.default.createElement(eui_1.EuiLink, Object.assign({ "aria-disabled": "true" }, props));
    }
    // Shorthand for pathname
    const pathname = path || _.get(props.to, 'pathname') || location.pathname;
    return (react_1.default.createElement(react_router_dom_1.Link, { children: children, to: { ...location, ...props.to, pathname, query }, className: `euiLink euiLink--primary ${props.className || ''}` }));
}
exports.ConnectedLinkComponent = ConnectedLinkComponent;
exports.ConnectedLink = react_router_dom_1.withRouter(ConnectedLinkComponent);
