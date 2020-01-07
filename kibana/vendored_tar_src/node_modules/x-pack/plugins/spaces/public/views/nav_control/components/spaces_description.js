"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const eui_1 = require("@elastic/eui");
const react_1 = tslib_1.__importDefault(require("react"));
const components_1 = require("../../../components");
const constants_1 = require("../../../lib/constants");
exports.SpacesDescription = (props) => {
    const panelProps = {
        className: 'spcDescription',
        title: 'Spaces',
    };
    return (react_1.default.createElement(eui_1.EuiContextMenuPanel, Object.assign({}, panelProps),
        react_1.default.createElement(eui_1.EuiText, { className: "spcDescription__text" },
            react_1.default.createElement("p", null, constants_1.getSpacesFeatureDescription())),
        react_1.default.createElement("div", { key: "manageSpacesButton", className: "spcDescription__manageButtonWrapper" },
            react_1.default.createElement(components_1.ManageSpacesButton, { size: "s", style: { width: `100%` }, userProfile: props.userProfile, onClick: props.onManageSpacesClick }))));
};
