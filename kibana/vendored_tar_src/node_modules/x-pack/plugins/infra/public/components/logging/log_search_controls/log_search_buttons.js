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
const classnames_1 = tslib_1.__importDefault(require("classnames"));
const React = tslib_1.__importStar(require("react"));
class LogSearchButtons extends React.PureComponent {
    constructor() {
        super(...arguments);
        this.handleJumpToPreviousSearchResult = () => {
            const { jumpToTarget, previousSearchResult } = this.props;
            if (previousSearchResult) {
                jumpToTarget(previousSearchResult);
            }
        };
        this.handleJumpToNextSearchResult = () => {
            const { jumpToTarget, nextSearchResult } = this.props;
            if (nextSearchResult) {
                jumpToTarget(nextSearchResult);
            }
        };
    }
    render() {
        const { className, previousSearchResult, nextSearchResult } = this.props;
        const classes = classnames_1.default('searchButtons', className);
        const hasPreviousSearchResult = !!previousSearchResult;
        const hasNextSearchResult = !!nextSearchResult;
        return (React.createElement(eui_1.EuiFlexGroup, { className: classes, gutterSize: "xs" },
            React.createElement(eui_1.EuiFlexItem, null,
                React.createElement(eui_1.EuiButtonEmpty, { onClick: this.handleJumpToPreviousSearchResult, iconType: "arrowLeft", iconSide: "left", isDisabled: !hasPreviousSearchResult, size: "s" },
                    React.createElement(react_1.FormattedMessage, { id: "xpack.infra.logs.search.previousButtonLabel", defaultMessage: "Previous" }))),
            React.createElement(eui_1.EuiFlexItem, null,
                React.createElement(eui_1.EuiButtonEmpty, { onClick: this.handleJumpToNextSearchResult, iconType: "arrowRight", iconSide: "right", isDisabled: !hasNextSearchResult, size: "s" },
                    React.createElement(react_1.FormattedMessage, { id: "xpack.infra.logs.search.nextButtonLabel", defaultMessage: "Next" })))));
    }
}
exports.LogSearchButtons = LogSearchButtons;
