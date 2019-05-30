"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const types_1 = require("../../../common/types");
async function incrementUIOpenOptionCounter(server, uiOpenOptionCounter) {
    const { getSavedObjectsRepository } = server.savedObjects;
    const { callWithInternalUser } = server.plugins.elasticsearch.getCluster('admin');
    const internalRepository = getSavedObjectsRepository(callWithInternalUser);
    await internalRepository.incrementCounter(types_1.UPGRADE_ASSISTANT_TYPE, types_1.UPGRADE_ASSISTANT_DOC_ID, `ui_open.${uiOpenOptionCounter}`);
}
async function upsertUIOpenOption(server, req) {
    const { overview, cluster, indices } = req.payload;
    if (overview) {
        await incrementUIOpenOptionCounter(server, 'overview');
    }
    if (cluster) {
        await incrementUIOpenOptionCounter(server, 'cluster');
    }
    if (indices) {
        await incrementUIOpenOptionCounter(server, 'indices');
    }
    return {
        overview,
        cluster,
        indices,
    };
}
exports.upsertUIOpenOption = upsertUIOpenOption;
