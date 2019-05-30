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
function initDeleteSpacesApi(server, routePreCheckLicenseFn) {
    server.route({
        method: 'DELETE',
        path: '/api/spaces/space/{id}',
        async handler(request, h) {
            const { SavedObjectsClient } = server.savedObjects;
            const spacesClient = server.plugins.spaces.spacesClient.getScopedClient(request);
            const id = request.params.id;
            let result;
            try {
                result = await spacesClient.delete(id);
            }
            catch (error) {
                if (SavedObjectsClient.errors.isNotFoundError(error)) {
                    return boom_1.default.notFound();
                }
                return errors_1.wrapError(error);
            }
            return h.response(result).code(204);
        },
        config: {
            pre: [routePreCheckLicenseFn],
        },
    });
}
exports.initDeleteSpacesApi = initDeleteSpacesApi;
