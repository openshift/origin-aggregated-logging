"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
const react_1 = tslib_1.__importStar(require("react"));
const eui_1 = require("@elastic/eui");
const react_2 = require("@kbn/i18n/react");
exports.DeprecationCountSummary = ({ deprecations, allDeprecations }) => (react_1.default.createElement(eui_1.EuiText, { size: "s" },
    allDeprecations.length ? (react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.checkupTab.numDeprecationsShownLabel", defaultMessage: "Showing {numShown} of {total}", values: { numShown: deprecations.length, total: allDeprecations.length } })) : (react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.checkupTab.noDeprecationsLabel", defaultMessage: "No deprecations" })),
    deprecations.length !== allDeprecations.length && (react_1.default.createElement(react_1.Fragment, null,
        '. ',
        react_1.default.createElement(react_2.FormattedMessage, { id: "xpack.upgradeAssistant.checkupTab.changeFiltersShowMoreLabel", description: "Explains how to show all deprecations if there are more available.", defaultMessage: "Change filter to show more." })))));
