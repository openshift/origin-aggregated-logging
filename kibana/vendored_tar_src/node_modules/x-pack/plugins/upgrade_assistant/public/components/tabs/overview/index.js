"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const react_1 = tslib_1.__importStar(require("react"));
const eui_1 = require("@elastic/eui");
const react_2 = require("@kbn/i18n/react");
const version_1 = require("../../../../common/version");
const error_banner_1 = require("../../error_banner");
const types_1 = require("../../types");
const steps_1 = require("./steps");
exports.OverviewTab = props => (react_1.default.createElement(react_1.Fragment, null,
    react_1.default.createElement(eui_1.EuiSpacer, null),
    react_1.default.createElement(eui_1.EuiText, { grow: false },
        react_1.default.createElement("p", null,
            react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.overviewTab.tabDetail", defaultMessage: "This assistant helps you prepare your cluster and indices for Elasticsearch\n           {nextEsVersion} For other issues that need your attention, see the Elasticsearch logs.", values: {
                    nextEsVersion: `${version_1.NEXT_MAJOR_VERSION}.x`,
                } }))),
    react_1.default.createElement(eui_1.EuiSpacer, null),
    props.alertBanner && (react_1.default.createElement(react_1.Fragment, null,
        props.alertBanner,
        react_1.default.createElement(eui_1.EuiSpacer, null))),
    react_1.default.createElement(eui_1.EuiPageContent, null,
        react_1.default.createElement(eui_1.EuiPageContentBody, null,
            props.loadingState === types_1.LoadingState.Success && react_1.default.createElement(steps_1.Steps, Object.assign({}, props)),
            props.loadingState === types_1.LoadingState.Loading && (react_1.default.createElement(eui_1.EuiFlexGroup, { justifyContent: "center" },
                react_1.default.createElement(eui_1.EuiFlexItem, { grow: false },
                    react_1.default.createElement(eui_1.EuiLoadingSpinner, null)))),
            props.loadingState === types_1.LoadingState.Error && (react_1.default.createElement(error_banner_1.LoadingErrorBanner, { loadingError: props.loadingError }))))));
