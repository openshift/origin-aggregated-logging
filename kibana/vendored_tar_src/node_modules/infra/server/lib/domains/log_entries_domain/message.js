"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const json_stable_stringify_1 = tslib_1.__importDefault(require("json-stable-stringify"));
function compileFormattingRules(rules) {
    const compiledRules = rules.map(compileRule);
    return {
        requiredFields: Array.from(new Set(compiledRules.reduce((combinedRequiredFields, { requiredFields }) => [
            ...combinedRequiredFields,
            ...requiredFields,
        ], []))),
        format: (fields) => {
            for (const compiledRule of compiledRules) {
                if (compiledRule.fulfillsCondition(fields)) {
                    return compiledRule.format(fields);
                }
            }
            return [];
        },
    };
}
exports.compileFormattingRules = compileFormattingRules;
const compileRule = (rule) => {
    const { conditionFields, fulfillsCondition } = compileCondition(rule.when);
    const { formattingFields, format } = compileFormattingInstructions(rule.format);
    return {
        requiredFields: [...conditionFields, ...formattingFields],
        fulfillsCondition,
        format,
    };
};
const compileCondition = (condition) => [compileExistsCondition, compileFieldValueCondition].reduce((compiledCondition, compile) => compile(condition) || compiledCondition, catchAllCondition);
const catchAllCondition = {
    conditionFields: [],
    fulfillsCondition: (fields) => false,
};
const compileExistsCondition = (condition) => 'exists' in condition
    ? {
        conditionFields: condition.exists,
        fulfillsCondition: (fields) => condition.exists.every(fieldName => fieldName in fields),
    }
    : null;
const compileFieldValueCondition = (condition) => 'values' in condition
    ? {
        conditionFields: Object.keys(condition.values),
        fulfillsCondition: (fields) => Object.entries(condition.values).every(([fieldName, expectedValue]) => fields[fieldName] === expectedValue),
    }
    : null;
const compileFormattingInstructions = (formattingInstructions) => formattingInstructions.reduce((combinedFormattingInstructions, formattingInstruction) => {
    const compiledFormattingInstruction = compileFormattingInstruction(formattingInstruction);
    return {
        formattingFields: [
            ...combinedFormattingInstructions.formattingFields,
            ...compiledFormattingInstruction.formattingFields,
        ],
        format: (fields) => [
            ...combinedFormattingInstructions.format(fields),
            ...compiledFormattingInstruction.format(fields),
        ],
    };
}, {
    formattingFields: [],
    format: (fields) => [],
});
const compileFormattingInstruction = (formattingInstruction) => [compileFieldReferenceFormattingInstruction, compileConstantFormattingInstruction].reduce((compiledFormattingInstruction, compile) => compile(formattingInstruction) || compiledFormattingInstruction, catchAllFormattingInstruction);
const catchAllFormattingInstruction = {
    formattingFields: [],
    format: (fields) => [
        {
            constant: 'invalid format',
        },
    ],
};
const compileFieldReferenceFormattingInstruction = (formattingInstruction) => 'field' in formattingInstruction
    ? {
        formattingFields: [formattingInstruction.field],
        format: (fields) => {
            const value = fields[formattingInstruction.field];
            return [
                {
                    field: formattingInstruction.field,
                    value: typeof value === 'object' ? json_stable_stringify_1.default(value) : `${value}`,
                    highlights: [],
                },
            ];
        },
    }
    : null;
const compileConstantFormattingInstruction = (formattingInstruction) => 'constant' in formattingInstruction
    ? {
        formattingFields: [],
        format: (fields) => [
            {
                constant: formattingInstruction.constant,
            },
        ],
    }
    : null;
