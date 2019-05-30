"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const adapter_types_1 = require("../../adapter_types");
exports.containerOverview = (timeField, indexPattern, interval) => ({
    id: 'containerOverview',
    requires: ['docker'],
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
        {
            id: 'memory',
            split_mode: 'everything',
            metrics: [
                {
                    field: 'docker.memory.usage.pct',
                    id: 'avg-memory',
                    type: adapter_types_1.InfraMetricModelMetricType.avg,
                },
            ],
        },
        {
            id: 'tx',
            split_mode: 'everything',
            metrics: [
                {
                    field: 'docker.network.out.bytes',
                    id: 'avg-network-out',
                    type: adapter_types_1.InfraMetricModelMetricType.avg,
                },
            ],
        },
        {
            id: 'rx',
            split_mode: 'everything',
            metrics: [
                {
                    field: 'docker.network.in.bytes',
                    id: 'avg-network-in',
                    type: adapter_types_1.InfraMetricModelMetricType.avg,
                },
            ],
        },
    ],
});
