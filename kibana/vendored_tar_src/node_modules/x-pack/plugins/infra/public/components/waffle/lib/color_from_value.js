"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const lodash_1 = require("lodash");
const polished_1 = require("polished");
const lib_1 = require("../../../lib/lib");
const type_guards_1 = require("./type_guards");
const OPERATOR_TO_FN = {
    [lib_1.InfraWaffleMapRuleOperator.eq]: lodash_1.eq,
    [lib_1.InfraWaffleMapRuleOperator.lt]: lodash_1.lt,
    [lib_1.InfraWaffleMapRuleOperator.lte]: lodash_1.lte,
    [lib_1.InfraWaffleMapRuleOperator.gte]: lodash_1.gte,
    [lib_1.InfraWaffleMapRuleOperator.gt]: lodash_1.gt,
};
const convertToRgbString = (color) => {
    return polished_1.toColorString(polished_1.parseToRgb(color));
};
exports.colorFromValue = (legend, value, bounds, defaultColor = 'rgba(217, 217, 217, 1)') => {
    try {
        if (type_guards_1.isInfraWaffleMapStepLegend(legend)) {
            return convertToRgbString(exports.calculateStepColor(legend, value, defaultColor));
        }
        if (type_guards_1.isInfraWaffleMapGradientLegend(legend)) {
            return convertToRgbString(exports.calculateGradientColor(legend, value, bounds, defaultColor));
        }
        return defaultColor;
    }
    catch (error) {
        return defaultColor;
    }
};
const normalizeValue = (min, max, value) => {
    return (value - min) / (max - min);
};
exports.calculateStepColor = (legend, value, defaultColor = 'rgba(217, 217, 217, 1)') => {
    return lodash_1.sortBy(legend.rules, 'sortBy').reduce((color, rule) => {
        const operatorFn = OPERATOR_TO_FN[rule.operator];
        if (operatorFn(value, rule.value)) {
            return rule.color;
        }
        return color;
    }, defaultColor);
};
exports.calculateGradientColor = (legend, value, bounds, defaultColor = 'rgba(0, 179, 164, 1)') => {
    if (legend.rules.length === 0) {
        return defaultColor;
    }
    if (legend.rules.length === 1) {
        return lodash_1.last(legend.rules).color;
    }
    const { min, max } = bounds;
    const sortedRules = lodash_1.sortBy(legend.rules, 'value');
    const normValue = normalizeValue(min, max, Number(value));
    const startRule = sortedRules.reduce((acc, rule) => {
        if (rule.value <= normValue) {
            return rule;
        }
        return acc;
    }, lodash_1.first(sortedRules));
    const endRule = sortedRules.filter(r => r !== startRule).find(r => r.value >= normValue);
    if (!endRule) {
        return startRule.color;
    }
    const mixValue = normalizeValue(startRule.value, endRule.value, normValue);
    return polished_1.mix(mixValue, endRule.color, startRule.color);
};
