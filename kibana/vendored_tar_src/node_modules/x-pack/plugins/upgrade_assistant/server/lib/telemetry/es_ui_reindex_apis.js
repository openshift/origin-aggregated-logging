"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const types_1 = require("../../../common/types");
async function incrementUIReindexOptionCounter(server, uiOpenOptionCounter) {
    const { getSavedObjectsRepository } = server.savedObjects;
    const { callWithInternalUser } = server.plugins.elasticsearch.getCluster('admin');
    const internalRepository = getSavedObjectsRepository(callWithInternalUser);
    await internalRepository.incrementCounter(types_1.UPGRADE_ASSISTANT_TYPE, types_1.UPGRADE_ASSISTANT_DOC_ID, `ui_reindex.${uiOpenOptionCounter}`);
}
async function upsertUIReindexOption(server, req) {
    const { close, open, start, stop } = req.payload;
    if (close) {
        await incrementUIReindexOptionCounter(server, 'close');
    }
    if (open) {
        await incrementUIReindexOptionCounter(server, 'open');
    }
    if (start) {
        await incrementUIReindexOptionCounter(server, 'start');
    }
    if (stop) {
        await incrementUIReindexOptionCounter(server, 'stop');
    }
    return {
        close,
        open,
        start,
        stop,
    };
}
exports.upsertUIReindexOption = upsertUIReindexOption;
