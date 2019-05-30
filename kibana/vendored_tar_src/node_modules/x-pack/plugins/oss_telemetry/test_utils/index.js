"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.getMockTaskInstance = () => ({ state: { runs: 0, stats: {} } });
const defaultMockSavedObjects = [
    {
        _id: 'visualization:coolviz-123',
        _source: {
            type: 'visualization',
            visualization: { visState: '{"type": "shell_beads"}' },
        },
    },
];
const defaultMockTaskDocs = [exports.getMockTaskInstance()];
exports.getMockCallWithInternal = (hits = defaultMockSavedObjects) => {
    return () => {
        return Promise.resolve({ hits: { hits } });
    };
};
exports.getMockTaskFetch = (docs = defaultMockTaskDocs) => {
    return () => Promise.resolve({ docs });
};
exports.getMockKbnServer = (mockCallWithInternal = exports.getMockCallWithInternal(), mockTaskFetch = exports.getMockTaskFetch()) => ({
    taskManager: {
        registerTaskDefinitions: (opts) => undefined,
        schedule: (opts) => Promise.resolve(),
        fetch: mockTaskFetch,
    },
    plugins: {
        elasticsearch: {
            getCluster: (cluster) => ({
                callWithInternalUser: mockCallWithInternal,
            }),
        },
        xpack_main: {},
    },
    usage: {
        collectorSet: {
            makeUsageCollector: () => '',
            register: () => undefined,
        },
    },
    config: () => ({ get: () => '' }),
    log: () => undefined,
});
