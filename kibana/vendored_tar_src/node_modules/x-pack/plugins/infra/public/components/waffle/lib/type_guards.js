"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const lib_1 = require("../../../lib/lib");
function isInfraWaffleMapStepLegend(subject) {
    return subject.type && subject.type === lib_1.InfraWaffleMapLegendMode.step;
}
exports.isInfraWaffleMapStepLegend = isInfraWaffleMapStepLegend;
function isInfraWaffleMapGradientLegend(subject) {
    return subject.type && subject.type === lib_1.InfraWaffleMapLegendMode.gradient;
}
exports.isInfraWaffleMapGradientLegend = isInfraWaffleMapGradientLegend;
