"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const memory_beats_adapter_1 = require("../adapters/beats/memory_beats_adapter");
const memory_tags_adapter_1 = require("../adapters/configuration_blocks/memory_tags_adapter");
const hapi_framework_adapter_1 = require("../adapters/framework/hapi_framework_adapter");
const memory_tags_adapter_2 = require("../adapters/tags/memory_tags_adapter");
const memory_tokens_adapter_1 = require("../adapters/tokens/memory_tokens_adapter");
const beat_events_1 = require("../beat_events");
const beats_1 = require("../beats");
const configuration_blocks_1 = require("../configuration_blocks");
const framework_1 = require("../framework");
const tags_1 = require("../tags");
const tokens_1 = require("../tokens");
function compose(server) {
    const framework = new framework_1.BackendFrameworkLib(new hapi_framework_adapter_1.HapiBackendFrameworkAdapter(undefined, server));
    const beatsAdapter = new memory_beats_adapter_1.MemoryBeatsAdapter(server.beatsDB || []);
    const configAdapter = new memory_tags_adapter_1.MemoryConfigurationBlockAdapter(server.configsDB || []);
    const tags = new tags_1.CMTagsDomain(new memory_tags_adapter_2.MemoryTagsAdapter(server.tagsDB || []), configAdapter, beatsAdapter);
    const configurationBlocks = new configuration_blocks_1.ConfigurationBlocksLib(configAdapter, tags);
    const tokens = new tokens_1.CMTokensDomain(new memory_tokens_adapter_1.MemoryTokensAdapter(server.tokensDB || []), {
        framework,
    });
    const beats = new beats_1.CMBeatsDomain(beatsAdapter, {
        tags,
        tokens,
        framework,
    });
    const beatEvents = new beat_events_1.BeatEventsLib({}, beats);
    const libs = {
        beatEvents,
        framework,
        beats,
        tags,
        tokens,
        configurationBlocks,
    };
    return libs;
}
exports.compose = compose;
