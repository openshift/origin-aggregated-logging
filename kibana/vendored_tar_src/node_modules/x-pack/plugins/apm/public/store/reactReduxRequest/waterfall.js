"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const react_1 = tslib_1.__importDefault(require("react"));
const waterfallV1_1 = require("./waterfallV1");
const waterfallV2_1 = require("./waterfallV2");
function WaterfallRequest({ urlParams, transaction, render }) {
    const hasTrace = transaction.hasOwnProperty('trace');
    if (hasTrace) {
        return (react_1.default.createElement(waterfallV2_1.WaterfallV2Request, { urlParams: urlParams, transaction: transaction, render: render }));
    }
    else {
        return (react_1.default.createElement(waterfallV1_1.WaterfallV1Request, { urlParams: urlParams, transaction: transaction, render: render }));
    }
}
exports.WaterfallRequest = WaterfallRequest;
