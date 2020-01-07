"use strict";
var _a;
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
const react_1 = tslib_1.__importDefault(require("react"));
/* istanbul ignore next */
const defaultContext = {
    breadcrumbs: [],
    addCrumb: (crumb) => null,
    removeCrumb: (crumb) => null,
};
_a = react_1.default.createContext(defaultContext), exports.Provider = _a.Provider, exports.Consumer = _a.Consumer;
