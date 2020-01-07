"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
const lodash_1 = require("lodash");
const constants_1 = require("../../../common/constants");
exports.omitBlacklistedHeaders = ({ job, decryptedHeaders, server, }) => {
    const filteredHeaders = lodash_1.omit(decryptedHeaders, constants_1.KBN_SCREENSHOT_HEADER_BLACKLIST);
    return { job, filteredHeaders, server };
};
