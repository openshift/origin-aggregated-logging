"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
// @ts-ignore
const crypto_1 = require("../../../server/lib/crypto");
exports.decryptJobHeaders = async ({ job, server, }) => {
    const crypto = crypto_1.cryptoFactory(server);
    const decryptedHeaders = await crypto.decrypt(job.headers);
    return { job, decryptedHeaders, server };
};
