"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const boom_1 = tslib_1.__importDefault(require("boom"));
const errors_1 = require("../../../lib/errors");
const space_schema_1 = require("../../../lib/space_schema");
function initPutSpacesApi(server, routePreCheckLicenseFn) {
    server.route({
        method: 'PUT',
        path: '/api/spaces/space/{id}',
        async handler(request) {
            const { SavedObjectsClient } = server.savedObjects;
            const spacesClient = server.plugins.spaces.spacesClient.getScopedClient(request);
            const space = request.payload;
            const id = request.params.id;
            let result;
            try {
                result = await spacesClient.update(id, { ...space });
            }
            catch (error) {
                if (SavedObjectsClient.errors.isNotFoundError(error)) {
                    return boom_1.default.notFound();
                }
                return errors_1.wrapError(error);
            }
            return result;
        },
        config: {
            validate: {
                payload: space_schema_1.spaceSchema,
            },
            pre: [routePreCheckLicenseFn],
        },
    });
}
exports.initPutSpacesApi = initPutSpacesApi;
