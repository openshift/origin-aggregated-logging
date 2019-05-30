"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const eui_1 = require("@elastic/eui");
const classnames_1 = tslib_1.__importDefault(require("classnames"));
const React = tslib_1.__importStar(require("react"));
const log_search_buttons_1 = require("./log_search_buttons");
const log_search_input_1 = require("./log_search_input");
class LogSearchControls extends React.PureComponent {
    render() {
        const { className, clearSearch, isLoadingSearchResults, previousSearchResult, nextSearchResult, jumpToTarget, search, } = this.props;
        const classes = classnames_1.default('searchControls', className);
        return (React.createElement(eui_1.EuiFlexGroup, { alignItems: "center", gutterSize: "xs", justifyContent: "flexStart", className: classes },
            React.createElement(eui_1.EuiFlexItem, null,
                React.createElement(log_search_input_1.LogSearchInput, { isLoading: isLoadingSearchResults, onClear: clearSearch, onSearch: search })),
            React.createElement(eui_1.EuiFlexItem, { grow: false },
                React.createElement(log_search_buttons_1.LogSearchButtons, { previousSearchResult: previousSearchResult, nextSearchResult: nextSearchResult, jumpToTarget: jumpToTarget }))));
    }
}
exports.LogSearchControls = LogSearchControls;
