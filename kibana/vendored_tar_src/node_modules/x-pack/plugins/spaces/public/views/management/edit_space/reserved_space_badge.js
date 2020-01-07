"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const react_1 = tslib_1.__importDefault(require("react"));
const eui_1 = require("@elastic/eui");
const react_2 = require("@kbn/i18n/react");
const common_1 = require("../../../../common");
exports.ReservedSpaceBadge = (props) => {
    const { space } = props;
    if (space && common_1.isReservedSpace(space)) {
        return (react_1.default.createElement(eui_1.EuiToolTip, { content: react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.spaces.management.reversedSpaceBadge.reversedSpacesCanBePartiallyModifiedTooltip", defaultMessage: "Reserved spaces are built-in and can only be partially modified." }) },
            react_1.default.createElement(eui_1.EuiIcon, { style: { verticalAlign: 'super' }, type: 'lock' })));
    }
    return null;
};
