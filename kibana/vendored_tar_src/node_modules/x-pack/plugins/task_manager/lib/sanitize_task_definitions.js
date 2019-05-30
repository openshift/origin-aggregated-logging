"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const joi_1 = tslib_1.__importDefault(require("joi"));
const task_1 = require("../task");
/**
 * Sanitizes the system's task definitions. Task definitions have optional properties, and
 * this ensures they all are given a reasonable default. This also overrides certain task
 * definition properties with kibana.yml overrides (such as the `override_num_workers` config
 * value).
 *
 * @param maxWorkers - The maxiumum numer of workers allowed to run at once
 * @param taskDefinitions - The Kibana task definitions dictionary
 * @param overrideNumWorkers - The kibana.yml overrides numWorkers per task type.
 */
function sanitizeTaskDefinitions(taskDefinitions = {}, maxWorkers, overrideNumWorkers) {
    return Object.keys(taskDefinitions).reduce((acc, type) => {
        const rawDefinition = taskDefinitions[type];
        rawDefinition.type = type;
        const definition = joi_1.default.attempt(rawDefinition, task_1.validateTaskDefinition);
        const numWorkers = Math.min(maxWorkers, overrideNumWorkers[definition.type] || definition.numWorkers || 1);
        acc[type] = {
            ...definition,
            numWorkers,
        };
        return acc;
    }, {});
}
exports.sanitizeTaskDefinitions = sanitizeTaskDefinitions;
