"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
const joi_1 = tslib_1.__importDefault(require("joi"));
const path_1 = require("path");
const constants_1 = require("./common/constants");
const plugin_1 = require("./common/constants/plugin");
const kibana_index_1 = require("./server/kibana.index");
const DEFAULT_ENROLLMENT_TOKENS_TTL_S = 10 * 60; // 10 minutes
exports.config = joi_1.default.object({
    enabled: joi_1.default.boolean().default(true),
    defaultUserRoles: joi_1.default.array()
        .items(joi_1.default.string())
        .default(['superuser']),
    encryptionKey: joi_1.default.string().default('xpack_beats_default_encryptionKey'),
    enrollmentTokensTtlInSeconds: joi_1.default.number()
        .integer()
        .min(1)
        .max(10 * 60 * 14) // No more then 2 weeks for security reasons
        .default(DEFAULT_ENROLLMENT_TOKENS_TTL_S),
}).default();
function beats(kibana) {
    return new kibana.Plugin({
        id: constants_1.PLUGIN.ID,
        require: ['kibana', 'elasticsearch', 'xpack_main'],
        publicDir: path_1.resolve(__dirname, 'public'),
        uiExports: {
            managementSections: ['plugins/beats_management'],
        },
        config: () => exports.config,
        configPrefix: plugin_1.CONFIG_PREFIX,
        init(server) {
            kibana_index_1.initServerWithKibana(server);
        },
    });
}
exports.beats = beats;
