"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const config_schemas_1 = require("../../../common/config_schemas");
const config_schemas_translations_map_1 = require("../../../common/config_schemas_translations_map");
const rest_beats_adapter_1 = require("../adapters/beats/rest_beats_adapter");
const rest_config_blocks_adapter_1 = require("../adapters/configuration_blocks/rest_config_blocks_adapter");
const memory_1 = require("../adapters/elasticsearch/memory");
const testing_framework_adapter_1 = require("../adapters/framework/testing_framework_adapter");
const node_axios_api_adapter_1 = require("../adapters/rest_api/node_axios_api_adapter");
const rest_tags_adapter_1 = require("../adapters/tags/rest_tags_adapter");
const rest_tokens_adapter_1 = require("../adapters/tokens/rest_tokens_adapter");
const beats_1 = require("../beats");
const configuration_blocks_1 = require("../configuration_blocks");
const elasticsearch_1 = require("../elasticsearch");
const framework_1 = require("../framework");
const tags_1 = require("../tags");
function compose(basePath) {
    const api = new node_axios_api_adapter_1.NodeAxiosAPIAdapter('elastic', 'changeme', basePath);
    const esAdapter = new memory_1.MemoryElasticsearchAdapter(() => true, () => '', []);
    const elasticsearchLib = new elasticsearch_1.ElasticsearchLib(esAdapter);
    const configBlocks = new configuration_blocks_1.ConfigBlocksLib(new rest_config_blocks_adapter_1.RestConfigBlocksAdapter(api), config_schemas_translations_map_1.translateConfigSchema(config_schemas_1.configBlockSchemas));
    const tags = new tags_1.TagsLib(new rest_tags_adapter_1.RestTagsAdapter(api), elasticsearchLib);
    const tokens = new rest_tokens_adapter_1.RestTokensAdapter(api);
    const beats = new beats_1.BeatsLib(new rest_beats_adapter_1.RestBeatsAdapter(api), elasticsearchLib);
    const framework = new framework_1.FrameworkLib(new testing_framework_adapter_1.TestingFrameworkAdapter({
        basePath,
        license: {
            type: 'gold',
            expired: false,
            expiry_date_in_millis: 34353453452345,
        },
        security: {
            enabled: true,
            available: true,
        },
        settings: {
            encryptionKey: 'xpack_beats_default_encryptionKey',
            enrollmentTokensTtlInSeconds: 10 * 60,
            defaultUserRoles: ['superuser'],
        },
    }, {
        username: 'joeuser',
        roles: ['beats_admin'],
        enabled: true,
        full_name: null,
        email: null,
    }, '6.7.0'));
    const libs = {
        framework,
        elasticsearch: elasticsearchLib,
        tags,
        tokens,
        beats,
        configBlocks,
    };
    return libs;
}
exports.compose = compose;
