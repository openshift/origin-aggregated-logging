"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.SCALE_FACTOR = 0.55;
exports.MAX_SIZE = Infinity;
exports.MIN_SIZE = 24;
function sizeOfSquares(width, height, totalItems, levels = 1) {
    const levelFactor = levels > 1 ? levels * 0.7 : 1;
    const scale = exports.SCALE_FACTOR / levelFactor;
    const x = width * scale;
    const y = height * scale;
    const possibleX = Math.ceil(Math.sqrt((totalItems * x) / y));
    let newX;
    let newY;
    if (Math.floor((possibleX * y) / x) * possibleX < totalItems) {
        newX = y / Math.ceil((possibleX * y) / x);
    }
    else {
        newX = x / possibleX;
    }
    const possibleY = Math.ceil(Math.sqrt((totalItems * y) / x));
    if (Math.floor((possibleY * x) / y) * possibleY < totalItems) {
        // does not fit
        newY = x / Math.ceil((x * possibleY) / y);
    }
    else {
        newY = y / possibleY;
    }
    const size = Math.max(newX, newY);
    return Math.min(Math.max(size, exports.MIN_SIZE), exports.MAX_SIZE);
}
exports.sizeOfSquares = sizeOfSquares;
