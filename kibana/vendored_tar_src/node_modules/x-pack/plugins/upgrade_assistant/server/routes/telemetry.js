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
const es_ui_open_apis_1 = require("../lib/telemetry/es_ui_open_apis");
const es_ui_reindex_apis_1 = require("../lib/telemetry/es_ui_reindex_apis");
function registerTelemetryRoutes(server) {
    server.route({
        path: '/api/upgrade_assistant/telemetry/ui_open',
        method: 'PUT',
        options: {
            validate: {
                payload: joi_1.default.object({
                    overview: joi_1.default.boolean().default(false),
                    cluster: joi_1.default.boolean().default(false),
                    indices: joi_1.default.boolean().default(false),
                }),
            },
        },
        async handler(request) {
            try {
                return await es_ui_open_apis_1.upsertUIOpenOption(server, request);
            }
            catch (e) {
                return boom_1.default.boomify(e, { statusCode: 500 });
            }
        },
    });
    server.route({
        path: '/api/upgrade_assistant/telemetry/ui_reindex',
        method: 'PUT',
        options: {
            validate: {
                payload: joi_1.default.object({
                    close: joi_1.default.boolean().default(false),
                    open: joi_1.default.boolean().default(false),
                    start: joi_1.default.boolean().default(false),
                    stop: joi_1.default.boolean().default(false),
                }),
            },
        },
        async handler(request) {
            try {
                return await es_ui_reindex_apis_1.upsertUIReindexOption(server, request);
            }
            catch (e) {
                return boom_1.default.boomify(e, { statusCode: 500 });
            }
        },
    });
}
exports.registerTelemetryRoutes = registerTelemetryRoutes;
