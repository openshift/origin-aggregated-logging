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
/*
 * This file contains the logic for managing the Kibana index version
 * (the shape of the mappings and documents in the index).
 */
const lodash_1 = require("lodash");
const schema_1 = require("../../schema");
const serialization_1 = require("../../serialization");
const validation_1 = require("../../validation");
const core_1 = require("../core");
const document_migrator_1 = require("../core/document_migrator");
/**
 * Manages the shape of mappings and documents in the Kibana index.
 *
 * @export
 * @class KibanaMigrator
 */
class KibanaMigrator {
    /**
     * Creates an instance of KibanaMigrator.
     *
     * @param opts
     * @prop {KbnServer} kbnServer - An instance of the Kibana server object.
     * @memberof KibanaMigrator
     */
    constructor({ kbnServer }) {
        /**
         * Migrates the mappings and documents in the Kibana index. This will run only
         * once and subsequent calls will return the result of the original call.
         *
         * @returns
         * @memberof KibanaMigrator
         */
        this.awaitMigration = lodash_1.once(async () => {
            const { server } = this.kbnServer;
            // Wait until the plugins have been found an initialized...
            await this.kbnServer.ready();
            // We can't do anything if the elasticsearch plugin has been disabled.
            if (!server.plugins.elasticsearch) {
                server.log(['warning', 'migration'], 'The elasticsearch plugin is disabled. Skipping migrations.');
                return { status: 'skipped' };
            }
            // Wait until elasticsearch is green...
            await server.plugins.elasticsearch.waitUntilReady();
            const config = server.config();
            const migrator = new core_1.IndexMigrator({
                batchSize: config.get('migrations.batchSize'),
                callCluster: server.plugins.elasticsearch.getCluster('admin').callWithInternalUser,
                documentMigrator: this.documentMigrator,
                index: config.get('kibana.index'),
                log: this.log,
                mappingProperties: this.mappingProperties,
                pollInterval: config.get('migrations.pollInterval'),
                scrollDuration: config.get('migrations.scrollDuration'),
                serializer: this.serializer,
            });
            return migrator.migrate();
        });
        this.kbnServer = kbnServer;
        this.serializer = new serialization_1.SavedObjectsSerializer(new schema_1.SavedObjectsSchema(kbnServer.uiExports.savedObjectSchemas));
        this.mappingProperties = mergeProperties(kbnServer.uiExports.savedObjectMappings || []);
        this.log = (meta, message) => kbnServer.server.log(meta, message);
        this.documentMigrator = new document_migrator_1.DocumentMigrator({
            kibanaVersion: kbnServer.version,
            migrations: kbnServer.uiExports.savedObjectMigrations || {},
            validateDoc: validation_1.docValidator(kbnServer.uiExports.savedObjectValidations || {}),
            log: this.log,
        });
    }
    /**
     * Gets the index mappings defined by Kibana's enabled plugins.
     *
     * @returns
     * @memberof KibanaMigrator
     */
    getActiveMappings() {
        return core_1.buildActiveMappings({ properties: this.mappingProperties });
    }
    /**
     * Migrates an individual doc to the latest version, as defined by the plugin migrations.
     *
     * @param {SavedObjectDoc} doc
     * @returns {SavedObjectDoc}
     * @memberof KibanaMigrator
     */
    migrateDocument(doc) {
        return this.documentMigrator.migrate(doc);
    }
}
exports.KibanaMigrator = KibanaMigrator;
/**
 * Merges savedObjectMappings properties into a single object, verifying that
 * no mappings are redefined.
 */
function mergeProperties(mappings) {
    return mappings.reduce((acc, { pluginId, properties }) => {
        const duplicate = Object.keys(properties).find(k => acc.hasOwnProperty(k));
        if (duplicate) {
            throw new Error(`Plugin ${pluginId} is attempting to redefine mapping "${duplicate}".`);
        }
        return Object.assign(acc, properties);
    }, {});
}
