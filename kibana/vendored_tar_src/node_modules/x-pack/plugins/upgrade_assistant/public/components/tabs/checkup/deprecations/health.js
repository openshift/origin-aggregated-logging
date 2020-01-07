"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const lodash_1 = require("lodash");
const react_1 = tslib_1.__importDefault(require("react"));
const eui_1 = require("@elastic/eui");
const i18n_1 = require("@kbn/i18n");
const constants_1 = require("../constants");
const LocalizedLevels = {
    warning: i18n_1.i18n.translate('xpack.upgradeAssistant.checkupTab.deprecations.warningLabel', {
        defaultMessage: 'warning',
    }),
    critical: i18n_1.i18n.translate('xpack.upgradeAssistant.checkupTab.deprecations.criticalLabel', {
        defaultMessage: 'critical',
    }),
};
exports.LocalizedActions = {
    warning: i18n_1.i18n.translate('xpack.upgradeAssistant.checkupTab.deprecations.warningActionTooltip', {
        defaultMessage: 'Resolving this issue before upgrading is advised, but not required.',
    }),
    critical: i18n_1.i18n.translate('xpack.upgradeAssistant.checkupTab.deprecations.criticalActionTooltip', {
        defaultMessage: 'Resolve this issue before upgrading.',
    }),
};
const SingleHealth = ({ level, label, }) => (react_1.default.createElement(react_1.default.Fragment, null,
    react_1.default.createElement(eui_1.EuiToolTip, { content: exports.LocalizedActions[level] },
        react_1.default.createElement(eui_1.EuiBadge, { color: constants_1.COLOR_MAP[level] }, label)),
    "\u2003"));
/**
 * Displays a summary health for a list of deprecations that shows the number and level of severity
 * deprecations in the list.
 */
exports.DeprecationHealth = ({ deprecations, single = false, }) => {
    if (deprecations.length === 0) {
        return react_1.default.createElement("span", null);
    }
    const levels = deprecations.map(d => constants_1.LEVEL_MAP[d.level]);
    if (single) {
        const highest = Math.max(...levels);
        const highestLevel = constants_1.REVERSE_LEVEL_MAP[highest];
        return react_1.default.createElement(SingleHealth, { level: highestLevel, label: LocalizedLevels[highestLevel] });
    }
    const countByLevel = lodash_1.countBy(levels);
    return (react_1.default.createElement(react_1.default.Fragment, null, Object.keys(countByLevel)
        .map(k => parseInt(k, 10))
        .sort()
        .map(level => [level, constants_1.REVERSE_LEVEL_MAP[level]])
        .map(([numLevel, stringLevel]) => (react_1.default.createElement(SingleHealth, { key: stringLevel, level: stringLevel, label: `${countByLevel[numLevel]} ${LocalizedLevels[stringLevel]}` })))));
};
