"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const d3_array_1 = require("d3-array");
const pick_1 = tslib_1.__importDefault(require("lodash/fp/pick"));
exports.isTimeKey = (value) => value &&
    typeof value === 'object' &&
    typeof value.time === 'number' &&
    typeof value.tiebreaker === 'number';
exports.pickTimeKey = (value) => pick_1.default(['time', 'tiebreaker'], value);
function compareTimeKeys(firstKey, secondKey, compareValues = d3_array_1.ascending) {
    const timeComparison = compareValues(firstKey.time, secondKey.time);
    if (timeComparison === 0) {
        const tiebreakerComparison = compareValues(firstKey.tiebreaker, secondKey.tiebreaker);
        if (tiebreakerComparison === 0 &&
            typeof firstKey.gid !== 'undefined' &&
            typeof secondKey.gid !== 'undefined') {
            return compareValues(firstKey.gid, secondKey.gid);
        }
        return tiebreakerComparison;
    }
    return timeComparison;
}
exports.compareTimeKeys = compareTimeKeys;
exports.compareToTimeKey = (keyAccessor, compareValues) => (value, key) => compareTimeKeys(keyAccessor(value), key, compareValues);
exports.getIndexAtTimeKey = (keyAccessor, compareValues) => {
    const comparator = exports.compareToTimeKey(keyAccessor, compareValues);
    const collectionBisector = d3_array_1.bisector(comparator);
    return (collection, key) => {
        const index = collectionBisector.left(collection, key);
        if (index >= collection.length) {
            return null;
        }
        if (comparator(collection[index], key) !== 0) {
            return null;
        }
        return index;
    };
};
exports.timeKeyIsBetween = (min, max, operand) => compareTimeKeys(min, operand) <= 0 && compareTimeKeys(max, operand) >= 0;
