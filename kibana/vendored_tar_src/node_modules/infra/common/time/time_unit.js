"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
var TimeUnit;
(function (TimeUnit) {
    TimeUnit[TimeUnit["Millisecond"] = 1] = "Millisecond";
    TimeUnit[TimeUnit["Second"] = 1000] = "Second";
    TimeUnit[TimeUnit["Minute"] = 60000] = "Minute";
    TimeUnit[TimeUnit["Hour"] = 3600000] = "Hour";
    TimeUnit[TimeUnit["Day"] = 86400000] = "Day";
    TimeUnit[TimeUnit["Month"] = 2592000000] = "Month";
    TimeUnit[TimeUnit["Year"] = 31104000000] = "Year";
})(TimeUnit = exports.TimeUnit || (exports.TimeUnit = {}));
exports.timeUnitLabels = {
    [TimeUnit.Millisecond]: 'ms',
    [TimeUnit.Second]: 's',
    [TimeUnit.Minute]: 'm',
    [TimeUnit.Hour]: 'h',
    [TimeUnit.Day]: 'd',
    [TimeUnit.Month]: 'M',
    [TimeUnit.Year]: 'y',
};
exports.elasticSearchTimeUnits = {
    [TimeUnit.Second]: 's',
    [TimeUnit.Minute]: 'm',
    [TimeUnit.Hour]: 'h',
    [TimeUnit.Day]: 'd',
    [TimeUnit.Month]: 'M',
    [TimeUnit.Year]: 'y',
};
exports.getElasticSearchTimeUnit = (scale) => exports.elasticSearchTimeUnits[scale];
