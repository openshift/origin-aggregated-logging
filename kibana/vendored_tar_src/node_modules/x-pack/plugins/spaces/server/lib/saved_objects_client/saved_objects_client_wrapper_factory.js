"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const spaces_saved_objects_client_1 = require("./spaces_saved_objects_client");
function spacesSavedObjectsClientWrapperFactory(spacesService, types) {
    return ({ client, request }) => new spaces_saved_objects_client_1.SpacesSavedObjectsClient({
        baseClient: client,
        request,
        spacesService,
        types,
    });
}
exports.spacesSavedObjectsClientWrapperFactory = spacesSavedObjectsClientWrapperFactory;
