"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const auth_1 = require("../adapters/auth");
const kibana_database_adapter_1 = require("../adapters/database/kibana_database_adapter");
const framework_1 = require("../adapters/framework");
const monitors_1 = require("../adapters/monitors");
const pings_1 = require("../adapters/pings");
const domains_1 = require("../domains");
function compose(hapiServer) {
    const framework = new framework_1.UMKibanaBackendFrameworkAdapter(hapiServer);
    const database = new kibana_database_adapter_1.UMKibanaDatabaseAdapter(hapiServer.plugins.elasticsearch);
    const pingsDomain = new domains_1.UMPingsDomain(new pings_1.ElasticsearchPingsAdapter(database), {});
    const authDomain = new domains_1.UMAuthDomain(new auth_1.UMXPackAuthAdapter(hapiServer.plugins.xpack_main), {});
    const monitorsDomain = new domains_1.UMMonitorsDomain(new monitors_1.ElasticsearchMonitorsAdapter(database), {});
    const domainLibs = {
        pings: pingsDomain,
        auth: authDomain,
        monitors: monitorsDomain,
    };
    const libs = {
        framework,
        database,
        ...domainLibs,
    };
    return libs;
}
exports.compose = compose;
