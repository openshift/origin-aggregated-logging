"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const get_1 = tslib_1.__importDefault(require("lodash/fp/get"));
const getOr_1 = tslib_1.__importDefault(require("lodash/fp/getOr"));
const polished_1 = require("polished");
const asPropReader = (reader) => typeof reader === 'function'
    ? reader
    : (props, defaultValue) => getOr_1.default(defaultValue, reader, props);
exports.switchProp = Object.assign((propName, options) => (props) => {
    const propValue = asPropReader(propName)(props, exports.switchProp.default);
    if (typeof propValue === 'undefined') {
        return;
    }
    return options instanceof Map ? options.get(propValue) : get_1.default(propValue, options);
}, {
    default: Symbol('default'),
});
exports.ifProp = (propName, pass, fail) => (props) => (asPropReader(propName)(props) ? pass : fail);
exports.tintOrShade = (textColor, color, fraction) => {
    return polished_1.parseToHsl(textColor).lightness > 0.5 ? polished_1.shade(fraction, color) : polished_1.tint(fraction, color);
};
