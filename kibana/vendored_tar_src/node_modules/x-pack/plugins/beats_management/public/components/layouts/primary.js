"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const eui_1 = require("@elastic/eui");
const react_1 = tslib_1.__importStar(require("react"));
const styled_components_1 = tslib_1.__importDefault(require("styled-components"));
const breadcrumb_1 = require("../navigation/breadcrumb");
class PrimaryLayout extends react_1.Component {
    constructor(props) {
        super(props);
        this.actionSection = null;
        this.renderAction = (component) => {
            this.actionSection = component;
            this.forceUpdate();
        };
    }
    render() {
        const children = this.props.children;
        return (react_1.default.createElement(react_1.default.Fragment, null,
            !this.props.hideBreadcrumbs && (react_1.default.createElement(breadcrumb_1.BreadcrumbConsumer, null, ({ breadcrumbs }) => (react_1.default.createElement(HeaderWrapper, null,
                react_1.default.createElement(eui_1.EuiHeaderSection, null,
                    react_1.default.createElement(eui_1.EuiHeaderBreadcrumbs, { breadcrumbs: breadcrumbs })))))),
            react_1.default.createElement(eui_1.EuiPage, null,
                react_1.default.createElement(eui_1.EuiPageBody, null,
                    react_1.default.createElement(eui_1.EuiPageHeader, null,
                        react_1.default.createElement(eui_1.EuiPageHeaderSection, null,
                            react_1.default.createElement(eui_1.EuiTitle, null,
                                react_1.default.createElement("h1", null, this.props.title))),
                        react_1.default.createElement(eui_1.EuiPageHeaderSection, null, (this.actionSection && this.actionSection()) || this.props.actionSection)),
                    react_1.default.createElement(eui_1.EuiPageContent, null,
                        react_1.default.createElement(eui_1.EuiPageContentBody, null, (children && typeof children === 'function'
                            ? children(this.renderAction)
                            : children) || react_1.default.createElement("span", null)))))));
    }
}
exports.PrimaryLayout = PrimaryLayout;
const HeaderWrapper = styled_components_1.default(eui_1.EuiHeader) `
  height: 29px;
`;
