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
const react_2 = tslib_1.__importStar(require("react"));
class BasicLoginFormUI extends react_2.Component {
    constructor() {
        super(...arguments);
        this.state = {
            hasError: false,
            isLoading: false,
            username: '',
            password: '',
            message: '',
        };
        this.renderMessage = () => {
            if (this.state.message) {
                return (react_2.default.createElement(react_2.Fragment, null,
                    react_2.default.createElement(eui_1.EuiCallOut, { size: "s", color: "danger", "data-test-subj": "loginErrorMessage", title: this.state.message, role: "alert" }),
                    react_2.default.createElement(eui_1.EuiSpacer, { size: "l" })));
            }
            if (this.props.infoMessage) {
                return (react_2.default.createElement(react_2.Fragment, null,
                    react_2.default.createElement(eui_1.EuiCallOut, { size: "s", color: "primary", "data-test-subj": "loginInfoMessage", title: this.props.infoMessage, role: "status" }),
                    react_2.default.createElement(eui_1.EuiSpacer, { size: "l" })));
            }
            return null;
        };
        this.isFormValid = () => {
            const { username, password } = this.state;
            return username && password;
        };
        this.onUsernameChange = (e) => {
            this.setState({
                username: e.target.value,
            });
        };
        this.onPasswordChange = (e) => {
            this.setState({
                password: e.target.value,
            });
        };
        this.submit = (e) => {
            e.preventDefault();
            if (!this.isFormValid()) {
                return;
            }
            this.setState({
                isLoading: true,
                message: '',
            });
            const { http, window, next, intl } = this.props;
            const { username, password } = this.state;
            http.post('./api/security/v1/login', { username, password }).then(() => (window.location.href = next), (error) => {
                const { statusCode = 500 } = error.data || {};
                let message = intl.formatMessage({
                    id: 'xpack.security.login.basicLoginForm.unknownErrorMessage',
                    defaultMessage: 'Oops! Error. Try again.',
                });
                if (statusCode === 401) {
                    message = intl.formatMessage({
                        id: 'xpack.security.login.basicLoginForm.invalidUsernameOrPasswordErrorMessage',
                        defaultMessage: 'Invalid username or password. Please try again.',
                    });
                }
                this.setState({
                    hasError: true,
                    message,
                    isLoading: false,
                });
            });
        };
    }
    render() {
        return (react_2.default.createElement(react_2.Fragment, null,
            this.renderMessage(),
            react_2.default.createElement(eui_1.EuiPanel, null,
                react_2.default.createElement("form", { onSubmit: this.submit },
                    react_2.default.createElement(eui_1.EuiFormRow, { label: react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.security.login.basicLoginForm.usernameFormRowLabel", defaultMessage: "Username" }) },
                        react_2.default.createElement(eui_1.EuiFieldText, { id: "username", name: "username", "data-test-subj": "loginUsername", value: this.state.username, onChange: this.onUsernameChange, disabled: this.state.isLoading, isInvalid: false, "aria-required": true, inputRef: this.setUsernameInputRef })),
                    react_2.default.createElement(eui_1.EuiFormRow, { label: react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.security.login.basicLoginForm.passwordFormRowLabel", defaultMessage: "Password" }) },
                        react_2.default.createElement(eui_1.EuiFieldText, { id: "password", name: "password", "data-test-subj": "loginPassword", type: "password", value: this.state.password, onChange: this.onPasswordChange, disabled: this.state.isLoading, isInvalid: false, "aria-required": true })),
                    react_2.default.createElement(eui_1.EuiButton, { fill: true, type: "submit", color: "primary", onClick: this.submit, isLoading: this.state.isLoading, "data-test-subj": "loginSubmit" },
                        react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.security.login.basicLoginForm.logInButtonLabel", defaultMessage: "Log in" }))))));
    }
    setUsernameInputRef(ref) {
        if (ref) {
            ref.focus();
        }
    }
}
exports.BasicLoginForm = react_1.injectI18n(BasicLoginFormUI);
