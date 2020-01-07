"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const ajax_1 = require("rxjs/ajax");
const operators_1 = require("rxjs/operators");
class InfraKibanaObservableApiAdapter {
    constructor({ basePath, xsrfToken }) {
        this.post = ({ url, body, }) => ajax_1.ajax({
            body: body ? JSON.stringify(body) : undefined,
            headers: {
                ...this.defaultHeaders,
                'Content-Type': 'application/json',
            },
            method: 'POST',
            responseType: 'json',
            timeout: 30000,
            url: `${this.basePath}/api/${url}`,
            withCredentials: true,
        }).pipe(operators_1.map(({ response, status }) => ({ response, status })));
        this.basePath = basePath;
        this.defaultHeaders = {
            'kbn-version': xsrfToken,
        };
    }
}
exports.InfraKibanaObservableApiAdapter = InfraKibanaObservableApiAdapter;
