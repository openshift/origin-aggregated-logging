"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const types_1 = require("../../graphql/types");
exports.createSourceStatusResolvers = (libs) => ({
    InfraSourceStatus: {
        async metricAliasExists(source, args, { req }) {
            return await libs.sourceStatus.hasMetricAlias(req, source.id);
        },
        async metricIndicesExist(source, args, { req }) {
            return await libs.sourceStatus.hasMetricIndices(req, source.id);
        },
        async metricIndices(source, args, { req }) {
            return await libs.sourceStatus.getMetricIndexNames(req, source.id);
        },
        async logAliasExists(source, args, { req }) {
            return await libs.sourceStatus.hasLogAlias(req, source.id);
        },
        async logIndicesExist(source, args, { req }) {
            return await libs.sourceStatus.hasLogIndices(req, source.id);
        },
        async logIndices(source, args, { req }) {
            return await libs.sourceStatus.getLogIndexNames(req, source.id);
        },
        async indexFields(source, args, { req }) {
            const fields = await libs.fields.getFields(req, source.id, args.indexType || types_1.InfraIndexType.ANY);
            return fields;
        },
    },
});
