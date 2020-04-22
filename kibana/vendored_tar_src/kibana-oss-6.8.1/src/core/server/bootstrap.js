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
const tslib_1 = require("tslib");
const chalk_1 = tslib_1.__importDefault(require("chalk"));
const cluster_1 = require("cluster");
const config_1 = require("./config");
const legacy_compat_1 = require("./legacy_compat");
const root_1 = require("./root");
async function bootstrap({ configs, cliArgs, applyConfigOverrides, features, }) {
    const env = config_1.Env.createDefault({
        configs,
        cliArgs,
        isDevClusterMaster: cluster_1.isMaster && cliArgs.dev && features.isClusterModeSupported,
    });
    const rawConfigService = new config_1.RawConfigService(env.configs, rawConfig => new legacy_compat_1.LegacyObjectToConfigAdapter(applyConfigOverrides(rawConfig)));
    rawConfigService.loadConfig();
    const root = new root_1.Root(rawConfigService.getConfig$(), env, onRootShutdown);
    function shutdown(reason) {
        rawConfigService.stop();
        return root.shutdown(reason);
    }
    try {
        await root.start();
    }
    catch (err) {
        await shutdown(err);
    }
    if (cliArgs.optimize) {
        const cliLogger = root.logger.get('cli');
        cliLogger.info('Optimization done.');
        await shutdown();
    }
    process.on('SIGHUP', () => {
        const cliLogger = root.logger.get('cli');
        cliLogger.info('Reloading logging configuration due to SIGHUP.', { tags: ['config'] });
        try {
            rawConfigService.reloadConfig();
        }
        catch (err) {
            return shutdown(err);
        }
        cliLogger.info('Reloaded logging configuration due to SIGHUP.', { tags: ['config'] });
    });
    process.on('SIGINT', () => shutdown());
    process.on('SIGTERM', () => shutdown());
}
exports.bootstrap = bootstrap;
function onRootShutdown(reason) {
    if (reason !== undefined) {
        // There is a chance that logger wasn't configured properly and error that
        // that forced root to shut down could go unnoticed. To prevent this we always
        // mirror such fatal errors in standard output with `console.error`.
        // tslint:disable no-console
        console.error(`\n${chalk_1.default.white.bgRed(' FATAL ')} ${reason}\n`);
    }
    process.exit(reason === undefined ? 0 : reason.processExitCode || 1);
}
