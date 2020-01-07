"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const auth_1 = require("../adapters/auth");
const test_backend_framework_adapter_1 = require("../adapters/framework/test_backend_framework_adapter");
const monitors_1 = require("../adapters/monitors");
const memory_pings_adapter_1 = require("../adapters/pings/memory_pings_adapter");
const domains_1 = require("../domains");
function compose(server) {
    const framework = new test_backend_framework_adapter_1.UMTestBackendFrameworkAdapter(server);
    const pingsDomain = new domains_1.UMPingsDomain(new memory_pings_adapter_1.MemoryPingsAdapter(server.pingsDB || []), framework);
    const authDomain = new domains_1.UMAuthDomain(new auth_1.UMMemoryAuthAdapter(server.xpack), framework);
    const monitorsDomain = new domains_1.UMMonitorsDomain(new monitors_1.UMMemoryMonitorsAdapter(server.pingsDB || []), framework);
    const libs = {
        auth: authDomain,
        framework,
        pings: pingsDomain,
        monitors: monitorsDomain,
    };
    return libs;
}
exports.compose = compose;
