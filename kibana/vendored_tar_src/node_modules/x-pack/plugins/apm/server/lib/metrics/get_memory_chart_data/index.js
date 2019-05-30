"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const fetcher_1 = require("./fetcher");
const transformer_1 = require("./transformer");
async function getMemoryChartData(args) {
    const result = await fetcher_1.fetch(args);
    return transformer_1.transform(result);
}
exports.getMemoryChartData = getMemoryChartData;
