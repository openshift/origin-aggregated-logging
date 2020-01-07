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
const components_1 = require("../../../../components");
exports.AdvancedSettingsTitle = (props) => (react_2.default.createElement(eui_1.EuiFlexGroup, { gutterSize: "s", responsive: false, alignItems: 'center' },
    react_2.default.createElement(eui_1.EuiFlexItem, { grow: false },
        react_2.default.createElement(components_1.SpaceAvatar, { space: props.space })),
    react_2.default.createElement(eui_1.EuiFlexItem, { style: { marginLeft: '10px' } },
        react_2.default.createElement(eui_1.EuiTitle, { size: "m" },
            react_2.default.createElement("h1", { "data-test-subj": "managementSettingsTitle" },
                react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.spaces.management.advancedSettingsTitle.settingsTitle", defaultMessage: "Settings" }))))));
