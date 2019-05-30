"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const lodash_1 = tslib_1.__importStar(require("lodash"));
const get_next_midnight_1 = require("../../get_next_midnight");
/*
 * Parse the response data into telemetry payload
 */
async function getStats(callCluster, index) {
    const searchParams = {
        size: 10000,
        index,
        ignoreUnavailable: true,
        filterPath: ['hits.hits._id', 'hits.hits._source.visualization'],
        body: {
            query: {
                bool: { filter: { term: { type: 'visualization' } } },
            },
        },
    };
    const esResponse = await callCluster('search', searchParams);
    const size = lodash_1.default.get(esResponse, 'hits.hits.length');
    if (size < 1) {
        return;
    }
    // `map` to get the raw types
    const visSummaries = esResponse.hits.hits.map((hit) => {
        const spacePhrases = hit._id.split(':');
        const space = spacePhrases.length === 3 ? spacePhrases[0] : 'default'; // if in a custom space, the format of a saved object ID is space:type:id
        const visualization = lodash_1.default.get(hit, '_source.visualization', { visState: '{}' });
        const visState = JSON.parse(visualization.visState);
        return {
            type: visState.type || '_na_',
            space,
        };
    });
    // organize stats per type
    const visTypes = lodash_1.groupBy(visSummaries, 'type');
    // get the final result
    return lodash_1.mapValues(visTypes, curr => {
        const total = curr.length;
        const spacesBreakdown = lodash_1.countBy(curr, 'space');
        const spaceCounts = lodash_1.default.values(spacesBreakdown);
        return {
            total,
            spaces_min: lodash_1.default.min(spaceCounts),
            spaces_max: lodash_1.default.max(spaceCounts),
            spaces_avg: total / spaceCounts.length,
        };
    });
}
function visualizationsTaskRunner(taskInstance, kbnServer) {
    const { server } = kbnServer;
    const { callWithInternalUser: callCluster } = server.plugins.elasticsearch.getCluster('data');
    const config = server.config();
    const index = config.get('kibana.index').toString(); // cast to string for TypeScript
    return async () => {
        let stats;
        let error;
        try {
            stats = await getStats(callCluster, index);
        }
        catch (err) {
            if (err.constructor === Error) {
                error = err.message;
            }
            else {
                error = err;
            }
        }
        return {
            runAt: get_next_midnight_1.getNextMidnight(),
            state: {
                runs: taskInstance.state.runs + 1,
                stats,
            },
            error,
        };
    };
}
exports.visualizationsTaskRunner = visualizationsTaskRunner;
