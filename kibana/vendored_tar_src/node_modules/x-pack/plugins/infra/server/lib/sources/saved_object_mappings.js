"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.infraSourceConfigurationSavedObjectType = 'infrastructure-ui-source';
exports.infraSourceConfigurationSavedObjectMappings = {
    [exports.infraSourceConfigurationSavedObjectType]: {
        properties: {
            name: {
                type: 'text',
            },
            description: {
                type: 'text',
            },
            metricAlias: {
                type: 'keyword',
            },
            logAlias: {
                type: 'keyword',
            },
            fields: {
                properties: {
                    container: {
                        type: 'keyword',
                    },
                    host: {
                        type: 'keyword',
                    },
                    pod: {
                        type: 'keyword',
                    },
                    tiebreaker: {
                        type: 'keyword',
                    },
                    timestamp: {
                        type: 'keyword',
                    },
                },
            },
        },
    },
};
