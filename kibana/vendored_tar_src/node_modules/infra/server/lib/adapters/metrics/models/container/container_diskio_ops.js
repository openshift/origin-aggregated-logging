"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const adapter_types_1 = require("../../adapter_types");
exports.containerDiskIOOps = (timeField, indexPattern, interval) => ({
    id: 'containerDiskIOOps',
    requires: ['docker.disk'],
    index_pattern: indexPattern,
    interval,
    time_field: timeField,
    type: 'timeseries',
    series: [
        {
            id: 'read',
            split_mode: 'everything',
            metrics: [
                {
                    field: 'docker.diskio.read.ops',
                    id: 'max-diskio-read-ops',
                    type: adapter_types_1.InfraMetricModelMetricType.max,
                },
                {
                    field: 'max-diskio-read-ops',
                    id: 'deriv-max-diskio-read-ops',
                    type: adapter_types_1.InfraMetricModelMetricType.derivative,
                    unit: '1s',
                },
                {
                    id: 'posonly-deriv-max-diskio-read-ops',
                    type: adapter_types_1.InfraMetricModelMetricType.calculation,
                    variables: [{ id: 'var-rate', name: 'rate', field: 'deriv-max-diskio-read-ops' }],
                    script: 'params.rate > 0.0 ? params.rate : 0.0',
                },
            ],
        },
        {
            id: 'write',
            split_mode: 'everything',
            metrics: [
                {
                    field: 'docker.diskio.write.ops',
                    id: 'max-diskio-write-ops',
                    type: adapter_types_1.InfraMetricModelMetricType.max,
                },
                {
                    field: 'max-diskio-write-ops',
                    id: 'deriv-max-diskio-write-ops',
                    type: adapter_types_1.InfraMetricModelMetricType.derivative,
                    unit: '1s',
                },
                {
                    id: 'posonly-deriv-max-diskio-write-ops',
                    type: adapter_types_1.InfraMetricModelMetricType.calculation,
                    variables: [{ id: 'var-rate', name: 'rate', field: 'deriv-max-diskio-write-ops' }],
                    script: 'params.rate > 0.0 ? params.rate : 0.0',
                },
                {
                    id: 'calc-invert-rate',
                    script: 'params.rate * -1',
                    type: adapter_types_1.InfraMetricModelMetricType.calculation,
                    variables: [
                        {
                            field: 'posonly-deriv-max-diskio-write-ops',
                            id: 'var-rate',
                            name: 'rate',
                        },
                    ],
                },
            ],
        },
    ],
});
