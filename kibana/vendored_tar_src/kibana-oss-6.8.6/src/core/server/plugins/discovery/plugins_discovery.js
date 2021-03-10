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
const fs_1 = require("fs");
const path_1 = require("path");
const rxjs_1 = require("rxjs");
const operators_1 = require("rxjs/operators");
const plugin_1 = require("../plugin");
const plugin_context_1 = require("../plugin_context");
const plugin_discovery_error_1 = require("./plugin_discovery_error");
const plugin_manifest_parser_1 = require("./plugin_manifest_parser");
const fsReadDir$ = rxjs_1.bindNodeCallback(fs_1.readdir);
const fsStat$ = rxjs_1.bindNodeCallback(fs_1.stat);
/**
 * Tries to discover all possible plugins based on the provided plugin config.
 * Discovery result consists of two separate streams, the one (`plugin$`) is
 * for the successfully discovered plugins and the other one (`error$`) is for
 * all the errors that occurred during discovery process.
 *
 * @param config Plugin config instance.
 * @param coreContext Kibana core values.
 * @internal
 */
function discover(config, coreContext) {
    const log = coreContext.logger.get('plugins-discovery');
    log.debug('Discovering plugins...');
    const discoveryResults$ = processPluginSearchPaths$(config.pluginSearchPaths, log).pipe(operators_1.mergeMap(pluginPathOrError => {
        return typeof pluginPathOrError === 'string'
            ? createPlugin$(pluginPathOrError, log, coreContext)
            : [pluginPathOrError];
    }), operators_1.shareReplay());
    return {
        plugin$: discoveryResults$.pipe(operators_1.filter((entry) => entry instanceof plugin_1.Plugin)),
        error$: discoveryResults$.pipe(operators_1.filter((entry) => !(entry instanceof plugin_1.Plugin))),
    };
}
exports.discover = discover;
/**
 * Iterates over every plugin search path and returns a merged stream of all
 * sub-directories. If directory cannot be read or it's impossible to get stat
 * for any of the nested entries then error is added into the stream instead.
 * @param pluginDirs List of the top-level directories to process.
 * @param log Plugin discovery logger instance.
 */
function processPluginSearchPaths$(pluginDirs, log) {
    return rxjs_1.from(pluginDirs).pipe(operators_1.mergeMap(dir => {
        log.debug(`Scanning "${dir}" for plugin sub-directories...`);
        return fsReadDir$(dir).pipe(operators_1.mergeMap((subDirs) => subDirs.map(subDir => path_1.resolve(dir, subDir))), operators_1.mergeMap(path => fsStat$(path).pipe(
        // Filter out non-directory entries from target directories, it's expected that
        // these directories may contain files (e.g. `README.md` or `package.json`).
        // We shouldn't silently ignore the entries we couldn't get stat for though.
        operators_1.mergeMap(pathStat => (pathStat.isDirectory() ? [path] : [])), operators_1.catchError(err => [plugin_discovery_error_1.PluginDiscoveryError.invalidPluginPath(path, err)]))), operators_1.catchError(err => [plugin_discovery_error_1.PluginDiscoveryError.invalidSearchPath(dir, err)]));
    }));
}
/**
 * Tries to load and parse the plugin manifest file located at the provided plugin
 * directory path and produces an error result if it fails to do so or plugin manifest
 * isn't valid.
 * @param path Path to the plugin directory where manifest should be loaded from.
 * @param log Plugin discovery logger instance.
 * @param coreContext Kibana core context.
 */
function createPlugin$(path, log, coreContext) {
    return rxjs_1.from(plugin_manifest_parser_1.parseManifest(path, coreContext.env.packageInfo)).pipe(operators_1.map(manifest => {
        log.debug(`Successfully discovered plugin "${manifest.id}" at "${path}"`);
        return new plugin_1.Plugin(path, manifest, plugin_context_1.createPluginInitializerContext(coreContext, manifest));
    }), operators_1.catchError(err => [err]));
}
