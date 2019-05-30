"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.filebeatMongodbRules = [
    {
        // pre-ECS
        when: {
            exists: ['mongodb.log.message'],
        },
        format: [
            {
                constant: '[MongoDB][',
            },
            {
                field: 'mongodb.log.component',
            },
            {
                constant: '] ',
            },
            {
                field: 'mongodb.log.message',
            },
        ],
    },
];
