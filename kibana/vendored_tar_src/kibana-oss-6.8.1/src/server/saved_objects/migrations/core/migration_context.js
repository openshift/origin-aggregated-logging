"use strict";
/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const build_active_mappings_1 = require("./build_active_mappings");
const elastic_index_1 = require("./elastic_index");
const migration_logger_1 = require("./migration_logger");
/**
 * Builds up an uber object which has all of the config options, settings,
 * and various info needed to migrate the source index.
 */
async function migrationContext(opts) {
    const { callCluster } = opts;
    const log = new migration_logger_1.MigrationLogger(opts.log);
    const alias = opts.index;
    const source = createSourceContext(await elastic_index_1.fetchInfo(callCluster, alias), alias);
    const dest = createDestContext(source, alias, opts.mappingProperties);
    return {
        callCluster,
        alias,
        source,
        dest,
        log,
        batchSize: opts.batchSize,
        documentMigrator: opts.documentMigrator,
        pollInterval: opts.pollInterval,
        scrollDuration: opts.scrollDuration,
        serializer: opts.serializer,
    };
}
exports.migrationContext = migrationContext;
function createSourceContext(source, alias) {
    if (source.exists && source.indexName === alias) {
        return {
            ...source,
            indexName: nextIndexName(alias, alias),
        };
    }
    return source;
}
function createDestContext(source, alias, mappingProperties) {
    const activeMappings = build_active_mappings_1.buildActiveMappings({ properties: mappingProperties });
    return {
        aliases: {},
        exists: false,
        indexName: nextIndexName(source.indexName, alias),
        mappings: {
            doc: {
                ...activeMappings.doc,
                properties: {
                    ...source.mappings.doc.properties,
                    ...activeMappings.doc.properties,
                },
            },
        },
    };
}
/**
 * Gets the next index name in a sequence, based on specified current index's info.
 * We're using a numeric counter to create new indices. So, `.kibana_1`, `.kibana_2`, etc
 * There are downsides to this, but it seemed like a simple enough approach.
 */
function nextIndexName(indexName, alias) {
    const indexSuffix = (indexName.match(/[\d]+$/) || [])[0];
    const indexNum = parseInt(indexSuffix, 10) || 0;
    return `${alias}_${indexNum + 1}`;
}
