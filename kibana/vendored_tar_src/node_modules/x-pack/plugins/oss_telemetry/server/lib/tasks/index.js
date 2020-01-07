"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const constants_1 = require("../../../constants");
const task_runner_1 = require("./visualizations/task_runner");
function registerTasks(server) {
    const { taskManager } = server;
    taskManager.registerTaskDefinitions({
        [constants_1.VIS_TELEMETRY_TASK]: {
            title: 'X-Pack telemetry calculator for Visualizations',
            type: constants_1.VIS_TELEMETRY_TASK,
            numWorkers: constants_1.VIS_TELEMETRY_TASK_NUM_WORKERS,
            createTaskRunner({ taskInstance, kbnServer }) {
                return {
                    run: task_runner_1.visualizationsTaskRunner(taskInstance, kbnServer),
                };
            },
        },
    });
}
exports.registerTasks = registerTasks;
function scheduleTasks(server) {
    const { taskManager } = server;
    const { kbnServer } = server.plugins.xpack_main.status.plugin;
    kbnServer.afterPluginsInit(async () => {
        try {
            await taskManager.schedule({
                id: `${constants_1.PLUGIN_ID}-${constants_1.VIS_TELEMETRY_TASK}`,
                taskType: constants_1.VIS_TELEMETRY_TASK,
                state: { stats: {}, runs: 0 },
            });
        }
        catch (e) {
            server.log(['warning', 'telemetry'], `Error scheduling task, received ${e.message}`);
        }
    });
}
exports.scheduleTasks = scheduleTasks;
