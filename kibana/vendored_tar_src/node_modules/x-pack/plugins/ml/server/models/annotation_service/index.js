"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const annotation_1 = require("./annotation");
function annotationServiceProvider(callWithRequest) {
    return {
        ...annotation_1.annotationProvider(callWithRequest),
    };
}
exports.annotationServiceProvider = annotationServiceProvider;
