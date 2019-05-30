"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const crypto_1 = require("crypto");
const fs = tslib_1.__importStar(require("fs"));
const lodash_1 = require("lodash");
const stream = tslib_1.__importStar(require("stream"));
const util = tslib_1.__importStar(require("util"));
const pipeline = util.promisify(stream.pipeline);
async function getIntegrityHashes(filepaths) {
    const hashes = await Promise.all(filepaths.map(getIntegrityHash));
    return lodash_1.zipObject(filepaths, hashes);
}
exports.getIntegrityHashes = getIntegrityHashes;
async function getIntegrityHash(filepath) {
    try {
        const output = crypto_1.createHash('md5');
        await pipeline(fs.createReadStream(filepath), output);
        const data = output.read();
        if (data instanceof Buffer) {
            return data.toString('hex');
        }
        return data;
    }
    catch (err) {
        return null;
    }
}
exports.getIntegrityHash = getIntegrityHash;
