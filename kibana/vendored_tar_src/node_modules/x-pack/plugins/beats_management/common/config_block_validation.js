"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
const t = tslib_1.__importStar(require("io-ts"));
const PathReporter_1 = require("io-ts/lib/PathReporter");
const config_schemas_1 = require("./config_schemas");
const domain_types_1 = require("./domain_types");
exports.validateConfigurationBlocks = (configurationBlocks) => {
    const validationMap = {
        isHosts: t.array(t.string),
        isString: t.string,
        isPeriod: t.string,
        isPath: t.string,
        isPaths: t.array(t.string),
        isYaml: t.string,
    };
    for (const [index, block] of configurationBlocks.entries()) {
        const blockSchema = config_schemas_1.configBlockSchemas.find(s => s.id === block.type);
        if (!blockSchema) {
            throw new Error(`Invalid config type of ${block.type} used in 'configuration_blocks' at index ${index}`);
        }
        const interfaceConfig = blockSchema.configs.reduce((props, config) => {
            if (config.options) {
                props[config.id] = t.union(config.options.map(opt => t.literal(opt.value)));
            }
            else if (config.validation) {
                props[config.id] = validationMap[config.validation];
            }
            return props;
        }, {});
        const runtimeInterface = domain_types_1.createConfigurationBlockInterface(t.literal(blockSchema.id), t.interface(interfaceConfig));
        const validationResults = runtimeInterface.decode(block);
        if (validationResults.isLeft()) {
            throw new Error(`configuration_blocks validation error, configuration_blocks at index ${index} is invalid. ${PathReporter_1.PathReporter.report(validationResults)[0]}`);
        }
    }
};
