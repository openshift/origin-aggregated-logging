"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const routes_1 = tslib_1.__importDefault(require("ui/routes"));
const kibana_framework_adapter_1 = require("../adapters/framework/kibana_framework_adapter");
function compose() {
    const libs = {
        framework: new kibana_framework_adapter_1.UMKibanaFrameworkAdapter(routes_1.default),
    };
    return libs;
}
exports.compose = compose;
