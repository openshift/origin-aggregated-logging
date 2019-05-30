"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const numeral_1 = tslib_1.__importDefault(require("@elastic/numeral"));
const i18n_1 = require("@kbn/i18n");
const lodash_1 = require("lodash");
const i18n_2 = require("x-pack/plugins/apm/common/i18n");
const SECONDS_CUT_OFF = 10 * 1000000; // 10 seconds (in microseconds)
const MILLISECONDS_CUT_OFF = 10 * 1000; // 10 milliseconds (in microseconds)
const SPACE = ' ';
function asSeconds(value, { withUnit = true, defaultValue = i18n_2.NOT_AVAILABLE_LABEL } = {}) {
    if (value == null) {
        return defaultValue;
    }
    const secondsLabel = SPACE +
        i18n_1.i18n.translate('xpack.apm.formatters.secondsTimeUnitLabel', {
            defaultMessage: 's'
        });
    const formatted = asDecimal(value / 1000000);
    return `${formatted}${withUnit ? secondsLabel : ''}`;
}
exports.asSeconds = asSeconds;
function asMillis(value, { withUnit = true, defaultValue = i18n_2.NOT_AVAILABLE_LABEL } = {}) {
    if (value == null) {
        return defaultValue;
    }
    const millisLabel = SPACE +
        i18n_1.i18n.translate('xpack.apm.formatters.millisTimeUnitLabel', {
            defaultMessage: 'ms'
        });
    const formatted = asInteger(value / 1000);
    return `${formatted}${withUnit ? millisLabel : ''}`;
}
exports.asMillis = asMillis;
function asMicros(value, { withUnit = true, defaultValue = i18n_2.NOT_AVAILABLE_LABEL } = {}) {
    if (value == null) {
        return defaultValue;
    }
    const microsLabel = SPACE +
        i18n_1.i18n.translate('xpack.apm.formatters.microsTimeUnitLabel', {
            defaultMessage: 'μs'
        });
    const formatted = asInteger(value);
    return `${formatted}${withUnit ? microsLabel : ''}`;
}
exports.asMicros = asMicros;
exports.getTimeFormatter = lodash_1.memoize((max) => {
    const unit = timeUnit(max);
    switch (unit) {
        case 's':
            return asSeconds;
        case 'ms':
            return asMillis;
        case 'us':
            return asMicros;
    }
});
function timeUnit(max) {
    if (max > SECONDS_CUT_OFF) {
        return 's';
    }
    else if (max > MILLISECONDS_CUT_OFF) {
        return 'ms';
    }
    else {
        return 'us';
    }
}
exports.timeUnit = timeUnit;
function asTime(value, { withUnit = true, defaultValue = i18n_2.NOT_AVAILABLE_LABEL } = {}) {
    if (value == null) {
        return defaultValue;
    }
    const formatter = exports.getTimeFormatter(value);
    return formatter(value, { withUnit, defaultValue });
}
exports.asTime = asTime;
function asDecimal(value) {
    return numeral_1.default(value).format('0,0.0');
}
exports.asDecimal = asDecimal;
function asInteger(value) {
    return numeral_1.default(value).format('0,0');
}
exports.asInteger = asInteger;
function tpmUnit(type) {
    return type === 'request'
        ? i18n_1.i18n.translate('xpack.apm.formatters.requestsPerMinLabel', {
            defaultMessage: 'rpm'
        })
        : i18n_1.i18n.translate('xpack.apm.formatters.transactionsPerMinLabel', {
            defaultMessage: 'tpm'
        });
}
exports.tpmUnit = tpmUnit;
function asPercent(numerator, denominator, fallbackResult = '') {
    if (!denominator || isNaN(numerator)) {
        return fallbackResult;
    }
    const decimal = numerator / denominator;
    return numeral_1.default(decimal).format('0.0%');
}
exports.asPercent = asPercent;
