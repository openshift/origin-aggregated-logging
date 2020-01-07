"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const types_1 = require("../../../../graphql/types");
const host_cpu_usage_1 = require("./host/host_cpu_usage");
const host_filesystem_1 = require("./host/host_filesystem");
const host_k8s_cpu_cap_1 = require("./host/host_k8s_cpu_cap");
const host_k8s_disk_cap_1 = require("./host/host_k8s_disk_cap");
const host_k8s_memory_cap_1 = require("./host/host_k8s_memory_cap");
const host_k8s_overview_1 = require("./host/host_k8s_overview");
const host_k8s_pod_cap_1 = require("./host/host_k8s_pod_cap");
const host_load_1 = require("./host/host_load");
const host_memory_usage_1 = require("./host/host_memory_usage");
const host_network_traffic_1 = require("./host/host_network_traffic");
const host_system_overview_1 = require("./host/host_system_overview");
const pod_cpu_usage_1 = require("./pod/pod_cpu_usage");
const pod_log_usage_1 = require("./pod/pod_log_usage");
const pod_memory_usage_1 = require("./pod/pod_memory_usage");
const pod_network_traffic_1 = require("./pod/pod_network_traffic");
const pod_overview_1 = require("./pod/pod_overview");
const container_cpu_kernel_1 = require("./container/container_cpu_kernel");
const container_cpu_usage_1 = require("./container/container_cpu_usage");
const container_disk_io_bytes_1 = require("./container/container_disk_io_bytes");
const container_diskio_ops_1 = require("./container/container_diskio_ops");
const container_memory_1 = require("./container/container_memory");
const container_network_traffic_1 = require("./container/container_network_traffic");
const container_overview_1 = require("./container/container_overview");
const nginx_active_connections_1 = require("./nginx/nginx_active_connections");
const nginx_hits_1 = require("./nginx/nginx_hits");
const nginx_request_rate_1 = require("./nginx/nginx_request_rate");
const nginx_requests_per_connection_1 = require("./nginx/nginx_requests_per_connection");
exports.metricModels = {
    [types_1.InfraMetric.hostSystemOverview]: host_system_overview_1.hostSystemOverview,
    [types_1.InfraMetric.hostCpuUsage]: host_cpu_usage_1.hostCpuUsage,
    [types_1.InfraMetric.hostFilesystem]: host_filesystem_1.hostFilesystem,
    [types_1.InfraMetric.hostK8sOverview]: host_k8s_overview_1.hostK8sOverview,
    [types_1.InfraMetric.hostK8sCpuCap]: host_k8s_cpu_cap_1.hostK8sCpuCap,
    [types_1.InfraMetric.hostK8sDiskCap]: host_k8s_disk_cap_1.hostK8sDiskCap,
    [types_1.InfraMetric.hostK8sMemoryCap]: host_k8s_memory_cap_1.hostK8sMemoryCap,
    [types_1.InfraMetric.hostK8sPodCap]: host_k8s_pod_cap_1.hostK8sPodCap,
    [types_1.InfraMetric.hostLoad]: host_load_1.hostLoad,
    [types_1.InfraMetric.hostMemoryUsage]: host_memory_usage_1.hostMemoryUsage,
    [types_1.InfraMetric.hostNetworkTraffic]: host_network_traffic_1.hostNetworkTraffic,
    [types_1.InfraMetric.podOverview]: pod_overview_1.podOverview,
    [types_1.InfraMetric.podCpuUsage]: pod_cpu_usage_1.podCpuUsage,
    [types_1.InfraMetric.podMemoryUsage]: pod_memory_usage_1.podMemoryUsage,
    [types_1.InfraMetric.podLogUsage]: pod_log_usage_1.podLogUsage,
    [types_1.InfraMetric.podNetworkTraffic]: pod_network_traffic_1.podNetworkTraffic,
    [types_1.InfraMetric.containerCpuKernel]: container_cpu_kernel_1.containerCpuKernel,
    [types_1.InfraMetric.containerCpuUsage]: container_cpu_usage_1.containerCpuUsage,
    [types_1.InfraMetric.containerDiskIOBytes]: container_disk_io_bytes_1.containerDiskIOBytes,
    [types_1.InfraMetric.containerDiskIOOps]: container_diskio_ops_1.containerDiskIOOps,
    [types_1.InfraMetric.containerNetworkTraffic]: container_network_traffic_1.containerNetworkTraffic,
    [types_1.InfraMetric.containerMemory]: container_memory_1.containerMemory,
    [types_1.InfraMetric.containerOverview]: container_overview_1.containerOverview,
    [types_1.InfraMetric.nginxHits]: nginx_hits_1.nginxHits,
    [types_1.InfraMetric.nginxRequestRate]: nginx_request_rate_1.nginxRequestRate,
    [types_1.InfraMetric.nginxActiveConnections]: nginx_active_connections_1.nginxActiveConnections,
    [types_1.InfraMetric.nginxRequestsPerConnection]: nginx_requests_per_connection_1.nginxRequestsPerConnection,
};
