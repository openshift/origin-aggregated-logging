"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
const react_1 = tslib_1.__importDefault(require("react"));
const react_router_dom_1 = require("react-router-dom");
exports.ChildRoutes = ({ routes, useSwitch = true, ...rest }) => {
    if (!routes) {
        return null;
    }
    const Parent = useSwitch ? react_router_dom_1.Switch : react_1.default.Fragment;
    return (react_1.default.createElement(Parent, null, routes.map(route => (react_1.default.createElement(react_router_dom_1.Route, { key: route.path, path: route.path, render: routeProps => {
            const Component = route.component;
            return react_1.default.createElement(Component, Object.assign({}, routeProps, { routes: route.routes }, rest));
        } })))));
};
