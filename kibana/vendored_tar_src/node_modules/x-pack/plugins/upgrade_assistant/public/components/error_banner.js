"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const lodash_1 = require("lodash");
const react_1 = tslib_1.__importDefault(require("react"));
const eui_1 = require("@elastic/eui");
const react_2 = require("@kbn/i18n/react");
exports.LoadingErrorBanner = ({ loadingError }) => {
    if (lodash_1.get(loadingError, 'response.status') === 403) {
        return (react_1.default.createElement(eui_1.EuiCallOut, { title: react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.forbiddenErrorCallout.calloutTitle", defaultMessage: "You do not have sufficient privileges to view this page." }), color: "danger", iconType: "cross" }));
    }
    return (react_1.default.createElement(eui_1.EuiCallOut, { title: react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.genericErrorCallout.calloutTitle", defaultMessage: "An error occurred while retrieving the checkup results." }), color: "danger", iconType: "cross" }, loadingError ? loadingError.message : null));
};
