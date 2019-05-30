"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const lodash_1 = require("lodash");
const react_1 = tslib_1.__importStar(require("react"));
const eui_1 = require("@elastic/eui");
const react_2 = require("@kbn/i18n/react");
const types_1 = require("../../../types");
const count_summary_1 = require("./count_summary");
const health_1 = require("./health");
const list_1 = require("./list");
// exported only for testing
exports.filterDeps = (level, search = '') => {
    const conditions = [];
    if (level !== types_1.LevelFilterOption.all) {
        conditions.push((dep) => dep.level === level);
    }
    if (search.length > 0) {
        // Change everything to lower case for a case-insensitive comparison
        conditions.push(dep => {
            try {
                const searchReg = new RegExp(search.toLowerCase());
                return Boolean(dep.message.toLowerCase().match(searchReg) ||
                    (dep.details && dep.details.toLowerCase().match(searchReg)) ||
                    (dep.index && dep.index.toLowerCase().match(searchReg)) ||
                    (dep.node && dep.node.toLowerCase().match(searchReg)));
            }
            catch (e) {
                // ignore any regexp errors.
                return true;
            }
        });
    }
    // Return true if every condition function returns true (boolean AND)
    return (dep) => conditions.map(c => c(dep)).every(t => t);
};
/**
 * A single accordion item for a grouped deprecation item.
 */
exports.DeprecationAccordion = ({ id, deprecations, title, currentGroupBy, forceExpand }) => {
    const hasIndices = Boolean(currentGroupBy === types_1.GroupByOption.message && deprecations.filter(d => d.index).length);
    const numIndices = hasIndices ? deprecations.length : null;
    return (react_1.default.createElement(eui_1.EuiAccordion, { id: id, className: "upgDeprecations__item", initialIsOpen: forceExpand, buttonContent: react_1.default.createElement("span", { className: "upgDeprecations__itemName" }, title), extraAction: react_1.default.createElement("div", null,
            hasIndices && (react_1.default.createElement(react_1.Fragment, null,
                react_1.default.createElement(eui_1.EuiBadge, { color: "hollow" },
                    react_1.default.createElement("span", { "data-test-subj": "indexCount" }, numIndices),
                    ' ',
                    react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.checkupTab.indicesBadgeLabel", defaultMessage: "{numIndices, plural, one {index} other {indices}}", values: { numIndices } })),
                "\u2003")),
            react_1.default.createElement(health_1.DeprecationHealth, { single: currentGroupBy === types_1.GroupByOption.message, deprecations: deprecations })) },
        react_1.default.createElement(list_1.DeprecationList, { deprecations: deprecations, currentGroupBy: currentGroupBy })));
};
const PER_PAGE = 25;
/**
 * Collection of calculated fields based on props, extracted for reuse in
 * `render` and `getDerivedStateFromProps`.
 */
const CalcFields = {
    filteredDeprecations(props) {
        const { allDeprecations = [], currentFilter, search } = props;
        return allDeprecations.filter(exports.filterDeps(currentFilter, search));
    },
    groups(props) {
        const { currentGroupBy } = props;
        return lodash_1.groupBy(CalcFields.filteredDeprecations(props), currentGroupBy);
    },
    numPages(props) {
        return Math.ceil(Object.keys(CalcFields.groups(props)).length / PER_PAGE);
    },
};
/**
 * Displays groups of deprecation messages in an accordion.
 */
class GroupedDeprecations extends react_1.default.Component {
    constructor() {
        super(...arguments);
        this.state = {
            forceExpand: false,
            // `expandNumber` is used as workaround to force EuiAccordion to re-render by
            // incrementing this number (used as a key) when expand all or collapse all is clicked.
            expandNumber: 0,
            currentPage: 0,
        };
        this.setExpand = (forceExpand) => {
            this.setState({ forceExpand, expandNumber: this.state.expandNumber + 1 });
        };
        this.setPage = (currentPage) => this.setState({ currentPage });
    }
    static getDerivedStateFromProps(nextProps, { currentPage }) {
        // If filters change and the currentPage is now bigger than the num of pages we're going to show,
        // reset the current page to 0.
        if (currentPage >= CalcFields.numPages(nextProps)) {
            return { currentPage: 0 };
        }
        else {
            return null;
        }
    }
    render() {
        const { currentGroupBy, allDeprecations = [] } = this.props;
        const { forceExpand, expandNumber, currentPage } = this.state;
        const filteredDeprecations = CalcFields.filteredDeprecations(this.props);
        const groups = CalcFields.groups(this.props);
        return (react_1.default.createElement(react_1.Fragment, null,
            react_1.default.createElement(eui_1.EuiFlexGroup, { responsive: false, alignItems: "center" },
                react_1.default.createElement(eui_1.EuiFlexItem, { grow: false },
                    react_1.default.createElement(eui_1.EuiButtonEmpty, { flush: "left", size: "s", onClick: () => this.setExpand(true), "data-test-subj": "expandAll" },
                        react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.checkupTab.controls.expandAllButtonLabel", defaultMessage: "Expand all" }))),
                react_1.default.createElement(eui_1.EuiFlexItem, { grow: false },
                    react_1.default.createElement(eui_1.EuiButtonEmpty, { flush: "left", size: "s", onClick: () => this.setExpand(false), "data-test-subj": "collapseAll" },
                        react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.checkupTab.controls.collapseAllButtonLabel", defaultMessage: "Collapse all" }))),
                react_1.default.createElement(eui_1.EuiFlexItem, null),
                react_1.default.createElement(eui_1.EuiFlexItem, { grow: false },
                    react_1.default.createElement(count_summary_1.DeprecationCountSummary, { allDeprecations: allDeprecations, deprecations: filteredDeprecations }))),
            react_1.default.createElement(eui_1.EuiSpacer, { size: "s" }),
            react_1.default.createElement("div", { className: "upgDeprecations" },
                Object.keys(groups)
                    .sort()
                    // Apply pagination
                    .slice(currentPage * PER_PAGE, (currentPage + 1) * PER_PAGE)
                    .map(groupName => [
                    react_1.default.createElement(exports.DeprecationAccordion, Object.assign({ key: expandNumber, id: `depgroup-${groupName}`, title: groupName, deprecations: groups[groupName] }, { currentGroupBy, forceExpand })),
                ]),
                Object.keys(groups).length > PER_PAGE && (react_1.default.createElement(react_1.Fragment, null,
                    react_1.default.createElement(eui_1.EuiSpacer, null),
                    react_1.default.createElement(eui_1.EuiFlexGroup, { justifyContent: "spaceAround" },
                        react_1.default.createElement(eui_1.EuiFlexItem, { grow: false },
                            react_1.default.createElement(eui_1.EuiPagination, { pageCount: CalcFields.numPages(this.props), activePage: currentPage, onPageClick: this.setPage }))))))));
    }
}
exports.GroupedDeprecations = GroupedDeprecations;
