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
exports.AdvancedSettingsSubtitle = (props) => (react_2.default.createElement(react_2.Fragment, null,
    react_2.default.createElement(eui_1.EuiSpacer, { size: 'm' }),
    react_2.default.createElement(eui_1.EuiCallOut, { color: "primary", iconType: "spacesApp", title: react_2.default.createElement("p", null,
            react_2.default.createElement(react_1.FormattedMessage, { id: "xpack.spaces.management.advancedSettingsSubtitle.applyingSettingsOnPageToSpaceDescription", defaultMessage: "The settings on this page apply to the {spaceName} space, unless otherwise specified.", values: {
                    spaceName: react_2.default.createElement("strong", null, props.space.name),
                } })) })));
