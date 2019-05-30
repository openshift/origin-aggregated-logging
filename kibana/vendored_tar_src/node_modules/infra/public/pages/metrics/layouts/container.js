"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const i18n_1 = require("@kbn/i18n");
const types_1 = require("../../../graphql/types");
const lib_1 = require("../../../lib/lib");
const nginx_1 = require("./nginx");
const types_2 = require("./types");
exports.containerLayoutCreator = theme => [
    {
        id: 'containerOverview',
        label: i18n_1.i18n.translate('xpack.infra.metricDetailPage.containerMetricsLayout.layoutLabel', {
            defaultMessage: 'Container',
        }),
        sections: [
            {
                id: types_1.InfraMetric.containerOverview,
                label: i18n_1.i18n.translate('xpack.infra.metricDetailPage.containerMetricsLayout.overviewSection.sectionLabel', {
                    defaultMessage: 'Overview',
                }),
                requires: ['docker.cpu', 'docker.memory', 'docker.network'],
                type: types_2.InfraMetricLayoutSectionType.gauges,
                visConfig: {
                    seriesOverrides: {
                        cpu: {
                            name: i18n_1.i18n.translate('xpack.infra.metricDetailPage.containerMetricsLayout.overviewSection.cpuUsageSeriesLabel', {
                                defaultMessage: 'CPU Usage',
                            }),
                            color: theme.eui.euiColorFullShade,
                            formatter: lib_1.InfraFormatterType.percent,
                            gaugeMax: 1,
                        },
                        memory: {
                            name: i18n_1.i18n.translate('xpack.infra.metricDetailPage.containerMetricsLayout.overviewSection.memoryUsageSeriesLabel', {
                                defaultMessage: 'Memory Usage',
                            }),
                            color: theme.eui.euiColorFullShade,
                            formatter: lib_1.InfraFormatterType.percent,
                            gaugeMax: 1,
                        },
                        rx: {
                            name: i18n_1.i18n.translate('xpack.infra.metricDetailPage.containerMetricsLayout.overviewSection.inboundRXSeriesLabel', {
                                defaultMessage: 'Inbound (RX)',
                            }),
                            color: theme.eui.euiColorFullShade,
                            formatter: lib_1.InfraFormatterType.bits,
                            formatterTemplate: '{{value}}/s',
                        },
                        tx: {
                            name: i18n_1.i18n.translate('xpack.infra.metricDetailPage.containerMetricsLayout.overviewSection.outboundTXSeriesLabel', {
                                defaultMessage: 'Outbound (TX)',
                            }),
                            color: theme.eui.euiColorFullShade,
                            formatter: lib_1.InfraFormatterType.bits,
                            formatterTemplate: '{{value}}/s',
                        },
                    },
                },
            },
            {
                id: types_1.InfraMetric.containerCpuUsage,
                label: i18n_1.i18n.translate('xpack.infra.metricDetailPage.containerMetricsLayout.cpuUsageSection.sectionLabel', {
                    defaultMessage: 'CPU Usage',
                }),
                requires: ['docker.cpu'],
                type: types_2.InfraMetricLayoutSectionType.chart,
                visConfig: {
                    stacked: true,
                    type: types_2.InfraMetricLayoutVisualizationType.area,
                    formatter: lib_1.InfraFormatterType.percent,
                    seriesOverrides: {
                        cpu: { color: theme.eui.euiColorVis1 },
                    },
                },
            },
            {
                id: types_1.InfraMetric.containerMemory,
                label: i18n_1.i18n.translate('xpack.infra.metricDetailPage.containerMetricsLayout.memoryUsageSection.sectionLabel', {
                    defaultMessage: 'Memory Usage',
                }),
                requires: ['docker.memory'],
                type: types_2.InfraMetricLayoutSectionType.chart,
                visConfig: {
                    stacked: true,
                    type: types_2.InfraMetricLayoutVisualizationType.area,
                    formatter: lib_1.InfraFormatterType.percent,
                    seriesOverrides: {
                        memory: { color: theme.eui.euiColorVis1 },
                    },
                },
            },
            {
                id: types_1.InfraMetric.containerNetworkTraffic,
                label: i18n_1.i18n.translate('xpack.infra.metricDetailPage.containerMetricsLayout.networkTrafficSection.sectionLabel', {
                    defaultMessage: 'Network Traffic',
                }),
                requires: ['docker.network'],
                type: types_2.InfraMetricLayoutSectionType.chart,
                visConfig: {
                    formatter: lib_1.InfraFormatterType.bits,
                    formatterTemplate: '{{value}}/s',
                    type: types_2.InfraMetricLayoutVisualizationType.area,
                    seriesOverrides: {
                        rx: {
                            color: theme.eui.euiColorVis1,
                            name: i18n_1.i18n.translate('xpack.infra.metricDetailPage.containerMetricsLayout.networkTrafficSection.networkRxRateSeriesLabel', {
                                defaultMessage: 'in',
                            }),
                        },
                        tx: {
                            color: theme.eui.euiColorVis2,
                            name: i18n_1.i18n.translate('xpack.infra.metricDetailPage.containerMetricsLayout.networkTrafficSection.networkTxRateSeriesLabel', {
                                defaultMessage: 'out',
                            }),
                        },
                    },
                },
            },
            {
                id: types_1.InfraMetric.containerDiskIOOps,
                label: i18n_1.i18n.translate('xpack.infra.metricDetailPage.containerMetricsLayout.diskIoOpsSection.sectionLabel', {
                    defaultMessage: 'Disk IO (Ops)',
                }),
                requires: ['docker.diskio'],
                type: types_2.InfraMetricLayoutSectionType.chart,
                visConfig: {
                    formatter: lib_1.InfraFormatterType.number,
                    formatterTemplate: '{{value}}/s',
                    type: types_2.InfraMetricLayoutVisualizationType.area,
                    seriesOverrides: {
                        read: {
                            color: theme.eui.euiColorVis1,
                            name: i18n_1.i18n.translate('xpack.infra.metricDetailPage.containerMetricsLayout.diskIoOpsSection.readRateSeriesLabel', {
                                defaultMessage: 'reads',
                            }),
                        },
                        write: {
                            color: theme.eui.euiColorVis2,
                            name: i18n_1.i18n.translate('xpack.infra.metricDetailPage.containerMetricsLayout.diskIoOpsSection.writeRateSeriesLabel', {
                                defaultMessage: 'writes',
                            }),
                        },
                    },
                },
            },
            {
                id: types_1.InfraMetric.containerDiskIOBytes,
                label: i18n_1.i18n.translate('xpack.infra.metricDetailPage.containerMetricsLayout.diskIoBytesSection.sectionLabel', {
                    defaultMessage: 'Disk IO (Bytes)',
                }),
                requires: ['docker.diskio'],
                type: types_2.InfraMetricLayoutSectionType.chart,
                visConfig: {
                    formatter: lib_1.InfraFormatterType.bytes,
                    formatterTemplate: '{{value}}/s',
                    type: types_2.InfraMetricLayoutVisualizationType.area,
                    seriesOverrides: {
                        read: {
                            color: theme.eui.euiColorVis1,
                            name: i18n_1.i18n.translate('xpack.infra.metricDetailPage.containerMetricsLayout.diskIoBytesSection.readRateSeriesLabel', {
                                defaultMessage: 'reads',
                            }),
                        },
                        write: {
                            color: theme.eui.euiColorVis2,
                            name: i18n_1.i18n.translate('xpack.infra.metricDetailPage.containerMetricsLayout.diskIoBytesSection.writeRateSeriesLabel', {
                                defaultMessage: 'writes',
                            }),
                        },
                    },
                },
            },
        ],
    },
    ...nginx_1.nginxLayoutCreator(theme),
];
