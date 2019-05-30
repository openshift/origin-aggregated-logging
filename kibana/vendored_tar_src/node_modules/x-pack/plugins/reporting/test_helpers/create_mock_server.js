"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
const lodash_1 = require("lodash");
exports.createMockServer = ({ settings = {} }) => {
    const mockServer = {
        expose: () => {
            ' ';
        },
        config: lodash_1.memoize(() => ({ get: jest.fn() })),
        info: {
            protocol: 'http',
        },
        plugins: {
            elasticsearch: {
                getCluster: lodash_1.memoize(() => {
                    return {
                        callWithRequest: jest.fn(),
                    };
                }),
            },
        },
        savedObjects: {
            getScopedSavedObjectsClient: jest.fn(),
        },
        uiSettingsServiceFactory: jest.fn().mockReturnValue({ get: jest.fn() }),
    };
    const defaultSettings = {
        'xpack.reporting.encryptionKey': 'testencryptionkey',
        'server.basePath': '/sbp',
        'server.host': 'localhost',
        'server.port': 5601,
        'xpack.reporting.kibanaServer': {},
    };
    mockServer.config().get.mockImplementation((key) => {
        return key in settings ? settings[key] : defaultSettings[key];
    });
    return mockServer;
};
