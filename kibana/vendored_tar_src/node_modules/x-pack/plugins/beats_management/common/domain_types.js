"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
const t = tslib_1.__importStar(require("io-ts"));
const config_schemas_1 = require("./config_schemas");
const io_ts_types_1 = require("./io_ts_types");
exports.OutputTypesArray = ['elasticsearch', 'logstash', 'kafka', 'redis'];
// Here we create the runtime check for a generic, unknown beat config type.
// We can also pass in optional params to create spacific runtime checks that
// can be used to validate blocs on the API and UI
exports.createConfigurationBlockInterface = (configType = t.union(config_schemas_1.configBlockSchemas.map(s => t.literal(s.id))), beatConfigInterface = t.Dictionary) => t.interface({
    id: t.union([t.undefined, t.string]),
    type: configType,
    description: t.union([t.undefined, t.string]),
    tag: t.string,
    config: beatConfigInterface,
    last_updated: t.union([t.undefined, t.number]),
}, 'ConfigBlock');
const BaseConfigurationBlock = exports.createConfigurationBlockInterface();
exports.RuntimeBeatTag = t.interface({
    id: t.union([t.undefined, t.string]),
    name: t.string,
    color: t.string,
    hasConfigurationBlocksTypes: t.array(t.string),
}, 'CMBeat');
exports.RuntimeBeatEvent = t.interface({
    type: t.union([t.literal('STATE'), t.literal('ERROR')]),
    beat: t.union([t.undefined, t.string]),
    timestamp: io_ts_types_1.DateFromString,
    event: t.type({
        type: t.union([
            t.literal('RUNNING'),
            t.literal('STARTING'),
            t.literal('IN_PROGRESS'),
            t.literal('CONFIG'),
            t.literal('FAILED'),
            t.literal('STOPPED'),
        ]),
        message: t.string,
        uuid: t.union([t.undefined, t.string]),
    }),
}, 'BeatEvent');
