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
const lodash_1 = require("lodash");
const operators_1 = require("rxjs/operators");
/** @internal */
class ConfigService {
    constructor(config$, env, logger) {
        this.config$ = config$;
        this.env = env;
        /**
         * Whenever a config if read at a path, we mark that path as 'handled'. We can
         * then list all unhandled config paths when the startup process is completed.
         */
        this.handledPaths = [];
        this.log = logger.get('config');
    }
    /**
     * Returns the full config object observable. This is not intended for
     * "normal use", but for features that _need_ access to the full object.
     */
    getConfig$() {
        return this.config$;
    }
    /**
     * Reads the subset of the config at the specified `path` and validates it
     * against the static `schema` on the given `ConfigClass`.
     *
     * @param path The path to the desired subset of the config.
     * @param ConfigClass A class (not an instance of a class) that contains a
     * static `schema` that we validate the config at the given `path` against.
     */
    atPath(path, ConfigClass) {
        return this.getDistinctConfig(path).pipe(operators_1.map(config => this.createConfig(path, config, ConfigClass)));
    }
    /**
     * Same as `atPath`, but returns `undefined` if there is no config at the
     * specified path.
     *
     * @see atPath
     */
    optionalAtPath(path, ConfigClass) {
        return this.getDistinctConfig(path).pipe(operators_1.map(config => config === undefined ? undefined : this.createConfig(path, config, ConfigClass)));
    }
    async isEnabledAtPath(path) {
        const enabledPath = createPluginEnabledPath(path);
        const config = await this.config$.pipe(operators_1.first()).toPromise();
        if (!config.has(enabledPath)) {
            return true;
        }
        const isEnabled = config.get(enabledPath);
        if (isEnabled === false) {
            // If the plugin is _not_ enabled, we mark the entire plugin path as
            // handled, as it's expected that it won't be used.
            this.markAsHandled(path);
            return false;
        }
        // If plugin enabled we mark the enabled path as handled, as we for example
        // can have plugins that don't have _any_ config except for this field, and
        // therefore have no reason to try to get the config.
        this.markAsHandled(enabledPath);
        return true;
    }
    async getUnusedPaths() {
        const config = await this.config$.pipe(operators_1.first()).toPromise();
        const handledPaths = this.handledPaths.map(pathToString);
        return config.getFlattenedPaths().filter(path => !isPathHandled(path, handledPaths));
    }
    async getUsedPaths() {
        const config = await this.config$.pipe(operators_1.first()).toPromise();
        const handledPaths = this.handledPaths.map(pathToString);
        return config.getFlattenedPaths().filter(path => isPathHandled(path, handledPaths));
    }
    createConfig(path, config, ConfigClass) {
        const namespace = Array.isArray(path) ? path.join('.') : path;
        const configSchema = ConfigClass.schema;
        if (configSchema === undefined || typeof configSchema.validate !== 'function') {
            throw new Error(`The config class [${ConfigClass.name}] did not contain a static 'schema' field, which is required when creating a config instance`);
        }
        const validatedConfig = ConfigClass.schema.validate(config, {
            dev: this.env.mode.dev,
            prod: this.env.mode.prod,
            ...this.env.packageInfo,
        }, namespace);
        return new ConfigClass(validatedConfig, this.env);
    }
    getDistinctConfig(path) {
        this.markAsHandled(path);
        return this.config$.pipe(operators_1.map(config => config.get(path)), operators_1.distinctUntilChanged(lodash_1.isEqual));
    }
    markAsHandled(path) {
        this.log.debug(`Marking config path as handled: ${path}`);
        this.handledPaths.push(path);
    }
}
exports.ConfigService = ConfigService;
const createPluginEnabledPath = (configPath) => {
    if (Array.isArray(configPath)) {
        return configPath.concat('enabled');
    }
    return `${configPath}.enabled`;
};
const pathToString = (path) => (Array.isArray(path) ? path.join('.') : path);
/**
 * A path is considered 'handled' if it is a subset of any of the already
 * handled paths.
 */
const isPathHandled = (path, handledPaths) => handledPaths.some(handledPath => path.startsWith(handledPath));
