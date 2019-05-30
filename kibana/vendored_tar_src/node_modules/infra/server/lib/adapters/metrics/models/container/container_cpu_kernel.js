"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const adapter_types_1 = require("../../adapter_types");
exports.containerCpuKernel = (timeField, indexPattern, interval) => ({
    id: 'containerCpuKernel',
    requires: ['docker.cpu'],
    index_pattern: indexPattern,
    interval,
    time_field: timeField,
    type: 'timeseries',
    series: [
        {
            id: 'kernel',
            split_mode: 'everything',
            metrics: [
                {
                    field: 'docker.cpu.kernel.pct',
                    id: 'avg-cpu-kernel',
                    type: adapter_types_1.InfraMetricModelMetricType.avg,
                },
            ],
        },
    ],
});
