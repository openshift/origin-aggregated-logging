"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const call_with_internal_user_factory_1 = require("../../client/call_with_internal_user_factory");
exports.ML_TELEMETRY_DOC_ID = 'ml-telemetry';
function createMlTelemetry(count = 0) {
    return {
        file_data_visualizer: {
            index_creation_count: count,
        },
    };
}
exports.createMlTelemetry = createMlTelemetry;
function storeMlTelemetry(server, mlTelemetry) {
    const savedObjectsClient = getSavedObjectsClient(server);
    savedObjectsClient.create('ml-telemetry', mlTelemetry, {
        id: exports.ML_TELEMETRY_DOC_ID,
        overwrite: true,
    });
}
exports.storeMlTelemetry = storeMlTelemetry;
function getSavedObjectsClient(server) {
    const { SavedObjectsClient, getSavedObjectsRepository } = server.savedObjects;
    const callWithInternalUser = call_with_internal_user_factory_1.callWithInternalUserFactory(server);
    const internalRepository = getSavedObjectsRepository(callWithInternalUser);
    return new SavedObjectsClient(internalRepository);
}
exports.getSavedObjectsClient = getSavedObjectsClient;
async function incrementFileDataVisualizerIndexCreationCount(server) {
    const savedObjectsClient = getSavedObjectsClient(server);
    try {
        const { attributes } = await savedObjectsClient.get('telemetry', 'telemetry');
        if (attributes.enabled === false) {
            return;
        }
    }
    catch (error) {
        // if we aren't allowed to get the telemetry document,
        // we assume we couldn't opt in to telemetry and won't increment the index count.
        return;
    }
    let indicesCount = 1;
    try {
        const { attributes } = (await savedObjectsClient.get('ml-telemetry', exports.ML_TELEMETRY_DOC_ID));
        indicesCount = attributes.file_data_visualizer.index_creation_count + 1;
    }
    catch (e) {
        /* silently fail, this will happen if the saved object doesn't exist yet. */
    }
    const mlTelemetry = createMlTelemetry(indicesCount);
    storeMlTelemetry(server, mlTelemetry);
}
exports.incrementFileDataVisualizerIndexCreationCount = incrementFileDataVisualizerIndexCreationCount;
