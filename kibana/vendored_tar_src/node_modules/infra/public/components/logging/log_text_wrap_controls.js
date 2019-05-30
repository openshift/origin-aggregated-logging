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
const React = tslib_1.__importStar(require("react"));
class LogTextWrapControls extends React.PureComponent {
    constructor() {
        super(...arguments);
        this.toggleWrap = () => {
            this.props.setTextWrap(!this.props.wrap);
        };
    }
    render() {
        const { wrap } = this.props;
        return (React.createElement(eui_1.EuiFormRow, { label: React.createElement(react_1.FormattedMessage, { id: "xpack.infra.logs.customizeLogs.lineWrappingFormRowLabel", defaultMessage: "Line Wrapping" }) },
            React.createElement(eui_1.EuiSwitch, { label: React.createElement(react_1.FormattedMessage, { id: "xpack.infra.logs.customizeLogs.wrapLongLinesSwitchLabel", defaultMessage: "Wrap long lines" }), checked: wrap, onChange: this.toggleWrap })));
    }
}
exports.LogTextWrapControls = LogTextWrapControls;
