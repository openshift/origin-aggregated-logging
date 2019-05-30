"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
// @ts-ignore
const chrome_1 = require("ui/chrome");
let isActive = false;
exports.loadingIndicator = {
    show: () => {
        if (!isActive) {
            chrome_1.loadingCount.increment();
            isActive = true;
        }
    },
    hide: () => {
        if (isActive) {
            chrome_1.loadingCount.decrement();
            isActive = false;
        }
    },
};
