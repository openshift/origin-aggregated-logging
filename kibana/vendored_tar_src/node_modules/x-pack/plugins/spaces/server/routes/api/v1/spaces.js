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
const spaces_url_parser_1 = require("../../../lib/spaces_url_parser");
const lib_1 = require("../../lib");
function initPrivateSpacesApi(server, routePreCheckLicenseFn) {
    server.route({
        method: 'POST',
        path: '/api/spaces/v1/space/{id}/select',
        async handler(request) {
            const { SavedObjectsClient } = server.savedObjects;
            const spacesClient = server.plugins.spaces.spacesClient.getScopedClient(request);
            const id = request.params.id;
            try {
                const existingSpace = await lib_1.getSpaceById(spacesClient, id, SavedObjectsClient.errors);
                if (!existingSpace) {
                    return boom_1.default.notFound();
                }
                const config = server.config();
                return {
                    location: spaces_url_parser_1.addSpaceIdToPath(config.get('server.basePath'), existingSpace.id, config.get('server.defaultRoute')),
                };
            }
            catch (error) {
                return errors_1.wrapError(error);
            }
        },
        config: {
            pre: [routePreCheckLicenseFn],
        },
    });
}
exports.initPrivateSpacesApi = initPrivateSpacesApi;
