"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const MEMORY_METRIC_NAMES = [
    'memoryUsedAvg',
    'memoryUsedMax'
];
function transform(result) {
    const { aggregations, hits } = result;
    const { timeseriesData, memoryUsedAvg, memoryUsedMax } = aggregations;
    const series = {
        memoryUsedAvg: [],
        memoryUsedMax: []
    };
    // using forEach here to avoid looping over the entire dataset
    // multiple times or doing a complicated, memory-heavy map/reduce
    timeseriesData.buckets.forEach(({ key, ...bucket }) => {
        MEMORY_METRIC_NAMES.forEach(name => {
            series[name].push({ x: key, y: bucket[name].value });
        });
    });
    return {
        series,
        overallValues: {
            memoryUsedAvg: memoryUsedAvg.value,
            memoryUsedMax: memoryUsedMax.value
        },
        totalHits: hits.total
    };
}
exports.transform = transform;
