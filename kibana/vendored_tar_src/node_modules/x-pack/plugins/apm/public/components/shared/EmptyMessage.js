"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const eui_1 = require("@elastic/eui");
const i18n_1 = require("@kbn/i18n");
const react_1 = tslib_1.__importDefault(require("react"));
const EmptyMessage = ({ heading = i18n_1.i18n.translate('xpack.apm.emptyMessage.noDataFoundLabel', {
    defaultMessage: 'No data found.'
}), subheading = i18n_1.i18n.translate('xpack.apm.emptyMessage.noDataFoundDescription', {
    defaultMessage: 'Try another time range or reset the search filter.'
}), hideSubheading = false }) => {
    return (react_1.default.createElement(eui_1.EuiEmptyPrompt, { titleSize: "s", title: react_1.default.createElement("div", null, heading), body: !hideSubheading && subheading }));
};
exports.EmptyMessage = EmptyMessage;
