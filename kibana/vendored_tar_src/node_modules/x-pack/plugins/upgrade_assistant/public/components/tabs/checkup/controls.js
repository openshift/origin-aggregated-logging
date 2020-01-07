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
const react_2 = require("@kbn/i18n/react");
const types_1 = require("../../types");
const filter_bar_1 = require("./filter_bar");
const group_by_bar_1 = require("./group_by_bar");
exports.CheckupControlsUI = ({ allDeprecations, loadingState, loadData, currentFilter, onFilterChange, search, onSearchChange, availableGroupByOptions, currentGroupBy, onGroupByChange, intl, }) => (react_1.default.createElement(eui_1.EuiFlexGroup, { alignItems: "center", wrap: true, responsive: false },
    react_1.default.createElement(eui_1.EuiFlexItem, { grow: true },
        react_1.default.createElement(eui_1.EuiFieldSearch, { "aria-label": "Filter", placeholder: intl.formatMessage({
                id: 'xpack.upgradeAssistant.checkupTab.controls.searchBarPlaceholder',
                defaultMessage: 'Filter',
            }), value: search, onChange: e => onSearchChange(e.target.value) })),
    react_1.default.createElement(filter_bar_1.FilterBar, Object.assign({}, { allDeprecations, currentFilter, onFilterChange })),
    react_1.default.createElement(group_by_bar_1.GroupByBar, Object.assign({}, { availableGroupByOptions, currentGroupBy, onGroupByChange })),
    react_1.default.createElement(eui_1.EuiFlexItem, { grow: false },
        react_1.default.createElement(eui_1.EuiButton, { fill: true, onClick: loadData, iconType: "refresh", isLoading: loadingState === types_1.LoadingState.Loading },
            react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.checkupTab.controls.refreshButtonLabel", defaultMessage: "Refresh" })))));
exports.CheckupControls = react_2.injectI18n(exports.CheckupControlsUI);
