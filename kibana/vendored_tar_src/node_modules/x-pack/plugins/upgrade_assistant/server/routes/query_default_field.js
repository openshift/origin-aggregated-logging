"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const boom_1 = tslib_1.__importDefault(require("boom"));
const joi_1 = tslib_1.__importDefault(require("joi"));
const es_version_precheck_1 = require("../lib/es_version_precheck");
const query_default_field_1 = require("../lib/query_default_field");
/**
 * Adds routes for detecting and fixing 6.x Metricbeat indices that need the
 * `index.query.default_field` index setting added.
 *
 * @param server
 */
function registerQueryDefaultFieldRoutes(server) {
    const { callWithRequest } = server.plugins.elasticsearch.getCluster('admin');
    server.route({
        path: '/api/upgrade_assistant/add_query_default_field/{indexName}',
        method: 'POST',
        options: {
            pre: [es_version_precheck_1.EsVersionPrecheck],
            validate: {
                params: joi_1.default.object({
                    indexName: joi_1.default.string().required(),
                }),
                payload: joi_1.default.object({
                    fieldTypes: joi_1.default.array()
                        .items(joi_1.default.string())
                        .required(),
                    otherFields: joi_1.default.array().items(joi_1.default.string()),
                }),
            },
        },
        async handler(request) {
            try {
                const { indexName } = request.params;
                const { fieldTypes, otherFields } = request.payload;
                return await query_default_field_1.addDefaultField(callWithRequest, request, indexName, new Set(fieldTypes), otherFields ? new Set(otherFields) : undefined);
            }
            catch (e) {
                if (e.status === 403) {
                    return boom_1.default.forbidden(e.message);
                }
                return boom_1.default.boomify(e, {
                    statusCode: 500,
                });
            }
        },
    });
}
exports.registerQueryDefaultFieldRoutes = registerQueryDefaultFieldRoutes;
