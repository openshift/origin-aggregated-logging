"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const react_1 = tslib_1.__importStar(require("react"));
const react_2 = require("@kbn/i18n/react");
const eui_1 = require("@elastic/eui");
const classnames_1 = tslib_1.__importDefault(require("classnames"));
const basic_login_form_1 = require("../basic_login_form");
const disabled_login_form_1 = require("../disabled_login_form");
class LoginPage extends react_1.Component {
    constructor() {
        super(...arguments);
        this.allowLogin = () => {
            if (this.props.requiresSecureConnection && !this.props.isSecureConnection) {
                return false;
            }
            return this.props.loginState.allowLogin && this.props.loginState.layout === 'form';
        };
        this.getLoginForm = () => {
            if (this.props.requiresSecureConnection && !this.props.isSecureConnection) {
                return (react_1.default.createElement(disabled_login_form_1.DisabledLoginForm, { title: react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.security.loginPage.requiresSecureConnectionTitle", defaultMessage: "A secure connection is required for log in" }), message: react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.security.loginPage.requiresSecureConnectionMessage", defaultMessage: "Contact your system administrator." }) }));
            }
            const layout = this.props.loginState.layout;
            switch (layout) {
                case 'form':
                    return react_1.default.createElement(basic_login_form_1.BasicLoginForm, Object.assign({}, this.props));
                case 'error-es-unavailable':
                    return (react_1.default.createElement(disabled_login_form_1.DisabledLoginForm, { title: react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.security.loginPage.esUnavailableTitle", defaultMessage: "Cannot connect to the Elasticsearch cluster" }), message: react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.security.loginPage.esUnavailableMessage", defaultMessage: "See the Kibana logs for details and try reloading the page." }) }));
                case 'error-xpack-unavailable':
                    return (react_1.default.createElement(disabled_login_form_1.DisabledLoginForm, { title: react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.security.loginPage.xpackUnavailableTitle", defaultMessage: "Cannot connect to the Elasticsearch cluster currently configured for Kibana." }), message: react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.security.loginPage.xpackUnavailableMessage", defaultMessage: "To use the full set of free features in this distribution of Kibana, please update Elasticsearch to the default distribution." }) }));
                default:
                    return (react_1.default.createElement(disabled_login_form_1.DisabledLoginForm, { title: react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.security.loginPage.unknownLayoutTitle", defaultMessage: "Unsupported login form layout." }), message: react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.security.loginPage.unknownLayoutMessage", defaultMessage: "Refer to the Kibana logs for more details and refresh to try again." }) }));
            }
        };
    }
    render() {
        const allowLogin = this.allowLogin();
        const contentHeaderClasses = classnames_1.default('loginWelcome__content', 'eui-textCenter', {
            ['loginWelcome__contentDisabledForm']: !allowLogin,
        });
        const contentBodyClasses = classnames_1.default('loginWelcome__content', 'loginWelcome-body', {
            ['loginWelcome__contentDisabledForm']: !allowLogin,
        });
        return (react_1.default.createElement("div", { className: "loginWelcome login-form" },
            react_1.default.createElement("header", { className: "loginWelcome__header" },
                react_1.default.createElement("div", { className: contentHeaderClasses },
                    react_1.default.createElement(eui_1.EuiSpacer, { size: "xxl" }),
                    react_1.default.createElement("span", { className: "loginWelcome__logo" },
                        react_1.default.createElement(eui_1.EuiIcon, { type: "logoKibana", size: "xxl" })),
                    react_1.default.createElement(eui_1.EuiTitle, { size: "l", className: "loginWelcome__title" },
                        react_1.default.createElement("h1", null,
                            react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.security.loginPage.welcomeTitle", defaultMessage: "Welcome to Kibana" }))),
                    react_1.default.createElement(eui_1.EuiText, { size: "s", color: "subdued", className: "loginWelcome__subtitle" },
                        react_1.default.createElement("p", null,
                            react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.security.loginPage.welcomeDescription", defaultMessage: "Your window into the Elastic Stack" }))),
                    react_1.default.createElement(eui_1.EuiSpacer, { size: "xl" }))),
            react_1.default.createElement("div", { className: contentBodyClasses },
                react_1.default.createElement(eui_1.EuiFlexGroup, { gutterSize: "l" },
                    react_1.default.createElement(eui_1.EuiFlexItem, null, this.getLoginForm())))));
    }
}
exports.LoginPage = LoginPage;
