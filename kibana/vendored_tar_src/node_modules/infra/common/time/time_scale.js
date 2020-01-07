"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const time_unit_1 = require("./time_unit");
exports.getMillisOfScale = (scale) => scale.unit * scale.value;
exports.getLabelOfScale = (scale) => `${scale.value}${time_unit_1.timeUnitLabels[scale.unit]}`;
exports.decomposeIntoUnits = (time, units) => units.reduce((result, unitMillis) => {
    const offset = result.reduce((accumulatedOffset, timeScale) => accumulatedOffset + exports.getMillisOfScale(timeScale), 0);
    const value = Math.floor((time - offset) / unitMillis);
    if (value > 0) {
        return [
            ...result,
            {
                unit: unitMillis,
                value,
            },
        ];
    }
    else {
        return result;
    }
}, []);
