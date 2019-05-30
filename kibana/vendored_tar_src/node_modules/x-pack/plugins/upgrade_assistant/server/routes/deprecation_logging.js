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
const es_deprecation_logging_apis_1 = require("../lib/es_deprecation_logging_apis");
const es_version_precheck_1 = require("../lib/es_version_precheck");
function registerDeprecationLoggingRoutes(server) {
    const { callWithRequest } = server.plugins.elasticsearch.getCluster('admin');
    server.route({
        path: '/api/upgrade_assistant/deprecation_logging',
        method: 'GET',
        options: {
            pre: [es_version_precheck_1.EsVersionPrecheck],
        },
        async handler(request) {
            try {
                return await es_deprecation_logging_apis_1.getDeprecationLoggingStatus(callWithRequest, request);
            }
            catch (e) {
                return boom_1.default.boomify(e, { statusCode: 500 });
            }
        },
    });
    server.route({
        path: '/api/upgrade_assistant/deprecation_logging',
        method: 'PUT',
        options: {
            pre: [es_version_precheck_1.EsVersionPrecheck],
            validate: {
                payload: joi_1.default.object({
                    isEnabled: joi_1.default.boolean(),
                }),
            },
        },
        async handler(request) {
            try {
                const { isEnabled } = request.payload;
                return await es_deprecation_logging_apis_1.setDeprecationLogging(callWithRequest, request, isEnabled);
            }
            catch (e) {
                return boom_1.default.boomify(e, { statusCode: 500 });
            }
        },
    });
}
exports.registerDeprecationLoggingRoutes = registerDeprecationLoggingRoutes;
