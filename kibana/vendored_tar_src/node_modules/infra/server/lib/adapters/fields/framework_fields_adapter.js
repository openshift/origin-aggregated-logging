"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
class FrameworkFieldsAdapter {
    constructor(framework) {
        this.framework = framework;
    }
    async getIndexFields(request, indices) {
        const indexPatternsService = this.framework.getIndexPatternsService(request);
        const response = await indexPatternsService.getFieldsForWildcard({
            pattern: indices,
        });
        return response;
    }
}
exports.FrameworkFieldsAdapter = FrameworkFieldsAdapter;
