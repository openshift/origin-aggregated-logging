"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const eui_1 = require("@elastic/eui");
const react_1 = require("@kbn/i18n/react");
const react_2 = tslib_1.__importDefault(require("react"));
exports.UnauthorizedPrompt = () => (react_2.default.createElement(eui_1.EuiEmptyPrompt, { iconType: "spacesApp", iconColor: 'danger', title: react_2.default.createElement("h2", null,
        react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.spaces.management.unauthorizedPrompt.permissionDeniedTitle", defaultMessage: "Permission denied" })), body: react_2.default.createElement("p", { "data-test-subj": "permissionDeniedMessage" },
        react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.spaces.management.unauthorizedPrompt.permissionDeniedDescription", defaultMessage: "You do not have permission to manage spaces." })) }));
