"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const mustache_1 = tslib_1.__importDefault(require("mustache"));
const lib_1 = require("../../lib/lib");
const data_1 = require("./data");
const number_1 = require("./number");
const percent_1 = require("./percent");
exports.FORMATTERS = {
    [lib_1.InfraFormatterType.number]: number_1.formatNumber,
    [lib_1.InfraFormatterType.abbreviatedNumber]: data_1.createDataFormatter(lib_1.InfraWaffleMapDataFormat.abbreviatedNumber),
    [lib_1.InfraFormatterType.bytes]: data_1.createDataFormatter(lib_1.InfraWaffleMapDataFormat.bytesDecimal),
    [lib_1.InfraFormatterType.bits]: data_1.createDataFormatter(lib_1.InfraWaffleMapDataFormat.bitsDecimal),
    [lib_1.InfraFormatterType.percent]: percent_1.formatPercent,
};
exports.createFormatter = (format, template = '{{value}}') => (val) => {
    if (val == null) {
        return '';
    }
    const fmtFn = exports.FORMATTERS[format];
    const value = fmtFn(Number(val));
    return mustache_1.default.render(template, { value });
};
