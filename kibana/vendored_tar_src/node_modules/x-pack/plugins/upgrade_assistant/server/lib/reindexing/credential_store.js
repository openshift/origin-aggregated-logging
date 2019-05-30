"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const crypto_1 = require("crypto");
const json_stable_stringify_1 = tslib_1.__importDefault(require("json-stable-stringify"));
exports.credentialStoreFactory = () => {
    const credMap = new Map();
    // Generates a stable hash for the reindex operation's current state.
    const getHash = (reindexOp) => crypto_1.createHash('sha256')
        .update(json_stable_stringify_1.default({ id: reindexOp.id, ...reindexOp.attributes }))
        .digest('base64');
    return {
        get(reindexOp) {
            return credMap.get(getHash(reindexOp));
        },
        set(reindexOp, credential) {
            credMap.set(getHash(reindexOp), credential);
        },
        clear() {
            for (const k of credMap.keys()) {
                credMap.delete(k);
            }
        },
    };
};
