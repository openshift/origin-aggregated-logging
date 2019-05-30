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
class ActionControl extends react_2.default.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            showModal: false,
        };
    }
    render() {
        const { action, actionHandler, danger, name, showWarning, warningHeading, warningMessage, } = this.props;
        return (react_2.default.createElement("div", null,
            react_2.default.createElement(eui_1.EuiButton, { size: "s", color: danger ? 'danger' : 'primary', disabled: this.props.disabled, onClick: showWarning ? () => this.setState({ showModal: true }) : () => actionHandler(action) }, name),
            this.state.showModal && (react_2.default.createElement(eui_1.EuiOverlayMask, null,
                react_2.default.createElement(eui_1.EuiConfirmModal, { buttonColor: danger ? 'danger' : 'primary', cancelButtonText: react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.confirmModal.cancelButtonLabel", defaultMessage: "Cancel" }), confirmButtonText: react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.confirmModal.confirmButtonLabel", defaultMessage: "Confirm" }), onConfirm: () => {
                        actionHandler(action);
                        this.setState({ showModal: false });
                    }, onCancel: () => this.setState({ showModal: false }), title: warningHeading ? (warningHeading) : (react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.beatsManagement.confirmModal.confirmWarningTitle", defaultMessage: "Confirm" })) }, warningMessage)))));
    }
}
exports.ActionControl = ActionControl;
