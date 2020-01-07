"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const constants_1 = require("../../common/constants");
const spaces_url_parser_1 = require("./spaces_url_parser");
function createSpacesService(server) {
    const serverBasePath = server.config().get('server.basePath');
    const contextCache = new WeakMap();
    function getSpaceId(request) {
        if (!contextCache.has(request)) {
            populateCache(request);
        }
        const { spaceId } = contextCache.get(request);
        return spaceId;
    }
    function isInDefaultSpace(request) {
        if (!contextCache.has(request)) {
            populateCache(request);
        }
        return contextCache.get(request).isInDefaultSpace;
    }
    function populateCache(request) {
        const spaceId = spaces_url_parser_1.getSpaceIdFromPath(request.getBasePath(), serverBasePath);
        contextCache.set(request, {
            spaceId,
            isInDefaultSpace: spaceId === constants_1.DEFAULT_SPACE_ID,
        });
    }
    return {
        getSpaceId,
        isInDefaultSpace,
    };
}
exports.createSpacesService = createSpacesService;
