"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const react_1 = tslib_1.__importDefault(require("react"));
const eui_1 = require("@elastic/eui");
const i18n_1 = require("@kbn/i18n");
const LocalizedOptions = {
    message: i18n_1.i18n.translate('xpack.upgradeAssistant.checkupTab.controls.groupByBar.byIssueLabel', {
        defaultMessage: 'by issue',
    }),
    index: i18n_1.i18n.translate('xpack.upgradeAssistant.checkupTab.controls.groupByBar.byIndexLabel', {
        defaultMessage: 'by index',
    }),
};
exports.GroupByBar = ({ availableGroupByOptions, currentGroupBy, onGroupByChange, }) => {
    if (availableGroupByOptions.length <= 1) {
        return null;
    }
    return (react_1.default.createElement(eui_1.EuiFlexItem, { grow: false },
        react_1.default.createElement(eui_1.EuiFilterGroup, null, availableGroupByOptions.map(option => (react_1.default.createElement(eui_1.EuiFilterButton, { key: option, onClick: onGroupByChange.bind(null, option), hasActiveFilters: currentGroupBy === option }, LocalizedOptions[option]))))));
};
