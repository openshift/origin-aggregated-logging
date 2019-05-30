"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const errors_1 = require("./errors");
const spaces_url_parser_1 = require("./spaces_url_parser");
async function getActiveSpace(spacesClient, requestBasePath, serverBasePath) {
    const spaceId = spaces_url_parser_1.getSpaceIdFromPath(requestBasePath, serverBasePath);
    try {
        return spacesClient.get(spaceId);
    }
    catch (e) {
        throw errors_1.wrapError(e);
    }
}
exports.getActiveSpace = getActiveSpace;
