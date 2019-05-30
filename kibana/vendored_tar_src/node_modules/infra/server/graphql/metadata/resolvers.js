"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.createMetadataResolvers = (libs) => ({
    InfraSource: {
        async metadataByNode(source, args, { req }) {
            const result = await libs.metadata.getMetadata(req, source.id, args.nodeId, args.nodeType);
            return result;
        },
    },
});
