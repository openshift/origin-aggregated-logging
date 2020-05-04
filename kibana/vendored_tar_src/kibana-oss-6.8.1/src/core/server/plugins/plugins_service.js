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
const operators_1 = require("rxjs/operators");
const discovery_1 = require("./discovery");
const plugins_config_1 = require("./plugins_config");
const plugins_system_1 = require("./plugins_system");
/** @internal */
class PluginsService {
    constructor(coreContext) {
        this.coreContext = coreContext;
        this.log = coreContext.logger.get('plugins-service');
        this.pluginsSystem = new plugins_system_1.PluginsSystem(coreContext);
    }
    async start() {
        this.log.debug('Starting plugins service');
        const config = await this.coreContext.configService
            .atPath('plugins', plugins_config_1.PluginsConfig)
            .pipe(operators_1.first())
            .toPromise();
        const { error$, plugin$ } = discovery_1.discover(config, this.coreContext);
        await this.handleDiscoveryErrors(error$);
        await this.handleDiscoveredPlugins(plugin$);
        if (!config.initialize || this.coreContext.env.isDevClusterMaster) {
            this.log.info('Plugin initialization disabled.');
            return new Map();
        }
        return await this.pluginsSystem.startPlugins();
    }
    async stop() {
        this.log.debug('Stopping plugins service');
        await this.pluginsSystem.stopPlugins();
    }
    async handleDiscoveryErrors(error$) {
        // At this stage we report only errors that can occur when new platform plugin
        // manifest is present, otherwise we can't be sure that the plugin is for the new
        // platform and let legacy platform to handle it.
        const errorTypesToReport = [
            discovery_1.PluginDiscoveryErrorType.IncompatibleVersion,
            discovery_1.PluginDiscoveryErrorType.InvalidManifest,
        ];
        const errors = await error$
            .pipe(operators_1.filter(error => errorTypesToReport.includes(error.type)), operators_1.tap(pluginError => this.log.error(pluginError)), operators_1.toArray())
            .toPromise();
        if (errors.length > 0) {
            throw new Error(`Failed to initialize plugins:${errors.map(err => `\n\t${err.message}`).join('')}`);
        }
    }
    async handleDiscoveredPlugins(plugin$) {
        const pluginEnableStatuses = new Map();
        await plugin$
            .pipe(operators_1.mergeMap(async (plugin) => {
            const isEnabled = await this.coreContext.configService.isEnabledAtPath(plugin.configPath);
            if (pluginEnableStatuses.has(plugin.name)) {
                throw new Error(`Plugin with id "${plugin.name}" is already registered!`);
            }
            pluginEnableStatuses.set(plugin.name, {
                plugin,
                isEnabled,
            });
        }))
            .toPromise();
        for (const [pluginName, { plugin, isEnabled }] of pluginEnableStatuses) {
            if (this.shouldEnablePlugin(pluginName, pluginEnableStatuses)) {
                this.pluginsSystem.addPlugin(plugin);
            }
            else if (isEnabled) {
                this.log.info(`Plugin "${pluginName}" has been disabled since some of its direct or transitive dependencies are missing or disabled.`);
            }
            else {
                this.log.info(`Plugin "${pluginName}" is disabled.`);
            }
        }
        this.log.debug(`Discovered ${pluginEnableStatuses.size} plugins.`);
    }
    shouldEnablePlugin(pluginName, pluginEnableStatuses) {
        const pluginInfo = pluginEnableStatuses.get(pluginName);
        return (pluginInfo !== undefined &&
            pluginInfo.isEnabled &&
            pluginInfo.plugin.requiredDependencies.every(dependencyName => this.shouldEnablePlugin(dependencyName, pluginEnableStatuses)));
    }
}
exports.PluginsService = PluginsService;
