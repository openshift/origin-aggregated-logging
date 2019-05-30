"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const types_1 = require("../../../pages/metrics/layouts/types");
const chart_section_1 = require("./chart_section");
const gauges_section_1 = require("./gauges_section");
exports.sections = {
    [types_1.InfraMetricLayoutSectionType.chart]: chart_section_1.ChartSection,
    [types_1.InfraMetricLayoutSectionType.gauges]: gauges_section_1.GaugesSection,
};
