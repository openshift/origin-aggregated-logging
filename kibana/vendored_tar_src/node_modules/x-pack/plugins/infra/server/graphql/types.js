"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
// ====================================================
// Enums
// ====================================================
var InfraIndexType;
(function (InfraIndexType) {
    InfraIndexType["ANY"] = "ANY";
    InfraIndexType["LOGS"] = "LOGS";
    InfraIndexType["METRICS"] = "METRICS";
})(InfraIndexType = exports.InfraIndexType || (exports.InfraIndexType = {}));
var InfraNodeType;
(function (InfraNodeType) {
    InfraNodeType["pod"] = "pod";
    InfraNodeType["container"] = "container";
    InfraNodeType["host"] = "host";
})(InfraNodeType = exports.InfraNodeType || (exports.InfraNodeType = {}));
var InfraPathType;
(function (InfraPathType) {
    InfraPathType["terms"] = "terms";
    InfraPathType["filters"] = "filters";
    InfraPathType["hosts"] = "hosts";
    InfraPathType["pods"] = "pods";
    InfraPathType["containers"] = "containers";
    InfraPathType["custom"] = "custom";
})(InfraPathType = exports.InfraPathType || (exports.InfraPathType = {}));
var InfraMetricType;
(function (InfraMetricType) {
    InfraMetricType["count"] = "count";
    InfraMetricType["cpu"] = "cpu";
    InfraMetricType["load"] = "load";
    InfraMetricType["memory"] = "memory";
    InfraMetricType["tx"] = "tx";
    InfraMetricType["rx"] = "rx";
    InfraMetricType["logRate"] = "logRate";
})(InfraMetricType = exports.InfraMetricType || (exports.InfraMetricType = {}));
var InfraMetric;
(function (InfraMetric) {
    InfraMetric["hostSystemOverview"] = "hostSystemOverview";
    InfraMetric["hostCpuUsage"] = "hostCpuUsage";
    InfraMetric["hostFilesystem"] = "hostFilesystem";
    InfraMetric["hostK8sOverview"] = "hostK8sOverview";
    InfraMetric["hostK8sCpuCap"] = "hostK8sCpuCap";
    InfraMetric["hostK8sDiskCap"] = "hostK8sDiskCap";
    InfraMetric["hostK8sMemoryCap"] = "hostK8sMemoryCap";
    InfraMetric["hostK8sPodCap"] = "hostK8sPodCap";
    InfraMetric["hostLoad"] = "hostLoad";
    InfraMetric["hostMemoryUsage"] = "hostMemoryUsage";
    InfraMetric["hostNetworkTraffic"] = "hostNetworkTraffic";
    InfraMetric["podOverview"] = "podOverview";
    InfraMetric["podCpuUsage"] = "podCpuUsage";
    InfraMetric["podMemoryUsage"] = "podMemoryUsage";
    InfraMetric["podLogUsage"] = "podLogUsage";
    InfraMetric["podNetworkTraffic"] = "podNetworkTraffic";
    InfraMetric["containerOverview"] = "containerOverview";
    InfraMetric["containerCpuKernel"] = "containerCpuKernel";
    InfraMetric["containerCpuUsage"] = "containerCpuUsage";
    InfraMetric["containerDiskIOOps"] = "containerDiskIOOps";
    InfraMetric["containerDiskIOBytes"] = "containerDiskIOBytes";
    InfraMetric["containerMemory"] = "containerMemory";
    InfraMetric["containerNetworkTraffic"] = "containerNetworkTraffic";
    InfraMetric["nginxHits"] = "nginxHits";
    InfraMetric["nginxRequestRate"] = "nginxRequestRate";
    InfraMetric["nginxActiveConnections"] = "nginxActiveConnections";
    InfraMetric["nginxRequestsPerConnection"] = "nginxRequestsPerConnection";
})(InfraMetric = exports.InfraMetric || (exports.InfraMetric = {}));
var InfraOperator;
(function (InfraOperator) {
    InfraOperator["gt"] = "gt";
    InfraOperator["gte"] = "gte";
    InfraOperator["lt"] = "lt";
    InfraOperator["lte"] = "lte";
    InfraOperator["eq"] = "eq";
})(InfraOperator = exports.InfraOperator || (exports.InfraOperator = {}));
