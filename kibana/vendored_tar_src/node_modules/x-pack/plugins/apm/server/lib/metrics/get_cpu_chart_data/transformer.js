"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const CPU_METRIC_NAMES = [
    'systemCPUAverage',
    'systemCPUMax',
    'processCPUAverage',
    'processCPUMax'
];
function transform(result) {
    const { aggregations, hits } = result;
    const { timeseriesData, systemCPUAverage, systemCPUMax, processCPUAverage, processCPUMax } = aggregations;
    const series = {
        systemCPUAverage: [],
        systemCPUMax: [],
        processCPUAverage: [],
        processCPUMax: []
    };
    // using forEach here to avoid looping over the entire dataset
    // 4 times or doing a complicated, memory-heavy map/reduce
    timeseriesData.buckets.forEach(({ key, ...bucket }) => {
        CPU_METRIC_NAMES.forEach(name => {
            series[name].push({ x: key, y: bucket[name].value });
        });
    });
    return {
        series,
        overallValues: {
            systemCPUAverage: systemCPUAverage.value,
            systemCPUMax: systemCPUMax.value,
            processCPUAverage: processCPUAverage.value,
            processCPUMax: processCPUMax.value
        },
        totalHits: hits.total
    };
}
exports.transform = transform;
