"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const graphql_tag_1 = tslib_1.__importDefault(require("graphql-tag"));
exports.metricsSchema = graphql_tag_1.default `
  enum InfraMetric {
    hostSystemOverview
    hostCpuUsage
    hostFilesystem
    hostK8sOverview
    hostK8sCpuCap
    hostK8sDiskCap
    hostK8sMemoryCap
    hostK8sPodCap
    hostLoad
    hostMemoryUsage
    hostNetworkTraffic
    podOverview
    podCpuUsage
    podMemoryUsage
    podLogUsage
    podNetworkTraffic
    containerOverview
    containerCpuKernel
    containerCpuUsage
    containerDiskIOOps
    containerDiskIOBytes
    containerMemory
    containerNetworkTraffic
    nginxHits
    nginxRequestRate
    nginxActiveConnections
    nginxRequestsPerConnection
  }

  type InfraMetricData {
    id: InfraMetric
    series: [InfraDataSeries!]!
  }

  type InfraDataSeries {
    id: ID!
    data: [InfraDataPoint!]!
  }

  type InfraDataPoint {
    timestamp: Float!
    value: Float
  }

  extend type InfraSource {
    metrics(
      nodeId: ID!
      nodeType: InfraNodeType!
      timerange: InfraTimerangeInput!
      metrics: [InfraMetric!]!
    ): [InfraMetricData!]!
  }
`;
