"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const adapter_types_1 = require("../../adapter_types");
exports.containerCpuUsage = (timeField, indexPattern, interval) => ({
    id: 'containerCpuUsage',
    requires: ['docker.cpu'],
    index_pattern: indexPattern,
    interval,
    time_field: timeField,
    type: 'timeseries',
    series: [
        {
            id: 'cpu',
            split_mode: 'everything',
            metrics: [
                {
                    field: 'docker.cpu.total.pct',
                    id: 'avg-cpu-total',
                    type: adapter_types_1.InfraMetricModelMetricType.avg,
                },
            ],
        },
    ],
});
