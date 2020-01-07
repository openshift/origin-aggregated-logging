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
const i18n_1 = require("@kbn/i18n");
const types_1 = require("../../types");
const LocalizedOptions = {
    all: i18n_1.i18n.translate('xpack.upgradeAssistant.checkupTab.controls.filterBar.allButtonLabel', {
        defaultMessage: 'all',
    }),
    critical: i18n_1.i18n.translate('xpack.upgradeAssistant.checkupTab.controls.filterBar.criticalButtonLabel', { defaultMessage: 'critical' }),
};
const allFilterOptions = Object.keys(types_1.LevelFilterOption);
exports.FilterBar = ({ allDeprecations = [], currentFilter, onFilterChange, }) => {
    const levelGroups = lodash_1.groupBy(allDeprecations, 'level');
    const levelCounts = Object.keys(levelGroups).reduce((counts, level) => {
        counts[level] = levelGroups[level].length;
        return counts;
    }, {});
    const allCount = allDeprecations.length;
    return (react_1.default.createElement(eui_1.EuiFlexItem, { grow: false },
        react_1.default.createElement(eui_1.EuiFilterGroup, null, allFilterOptions.map(option => (react_1.default.createElement(eui_1.EuiFilterButton, { key: option, onClick: onFilterChange.bind(null, option), hasActiveFilters: currentFilter === option, numFilters: option === types_1.LevelFilterOption.all ? allCount : levelCounts[option] || undefined }, LocalizedOptions[option]))))));
};
