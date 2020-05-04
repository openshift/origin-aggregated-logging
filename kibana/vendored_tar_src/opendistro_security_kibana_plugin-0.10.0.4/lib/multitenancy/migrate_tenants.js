/*
 * Copyright 2015-2018 _floragunn_ GmbH
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */
/*
 * Portions Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

import _ from 'lodash';
import Boom from 'boom';
import elasticsearch from 'elasticsearch';
import wrapElasticsearchError from './../backend/errors/wrap_elasticsearch_error';
import { KibanaMigrator } from '../../../../src/server/saved_objects/migrations';

async function migrateTenants (server) {

    const backend = server.plugins.opendistro_security.getSecurityBackend();

    try {
        let tenantInfo = await backend.getTenantInfoWithInternalUser();

        if (tenantInfo) {
             let indexNames = Object.keys(tenantInfo);
             for (var index = 0; index < indexNames.length; ++index) {
                 await migrateTenantIndex(indexNames[index], server);
             }
         }
    } catch (error) {
        server.log(['error', 'migration'], error);
        throw error;
    }
}

async function migrateTenantIndex(tenantIndexName, server) {
    const {kbnServer} = mockKbnServer(server.kibanaMigrator.kbnServer, server, tenantIndexName);
    const migrator = new KibanaMigrator({kbnServer});
    await  migrator.awaitMigration();
}

async function migrateTenant(tenantIndexName, force, server) {
    const backend = server.plugins.opendistro_security.getSecurityBackend();
    try {
        let tenantInfo = await backend.getTenantInfoWithInternalUser();
      
        if (tenantInfo) {
            if (tenantInfo[tenantIndexName] || (force == true)) {
                await migrateTenantIndex(tenantIndexName, server);
                return {statusCode:200, message: tenantIndexName + " migrated."}
            } else {
                return Boom.badRequest('Index ' + tenantIndexName + ' not found or not a tenand index. Force migration: ' + force);
            }
        } else {
            return Boom.badImplementation("Could not fetch tenant info.");
        }
    } catch (error) {
        server.log(['error', 'migration'], error);
        return wrapElasticsearchError(error);
    }
}

function mockKbnServer(originalKbnServer, server, indexname) {

    const kbnServer = {
        version: originalKbnServer.version,
        ready: originalKbnServer.ready,
        uiExports: originalKbnServer.uiExports,
        server: {
            config: () => ({
                get: ((name) => {
                    switch (name) {
                        case 'kibana.index':
                            return indexname;
                        case 'migrations.batchSize':
                            return originalKbnServer.server.config().get("migrations.batchSize");
                        case 'migrations.pollInterval':
                            return originalKbnServer.server.config().get("migrations.pollInterval");
                        case 'migrations.scrollDuration':
                            return originalKbnServer.server.config().get("migrations.scrollDuration");
                        default:
                            throw new Error(`Unexpected config ${name}`);
                    }
                })
            }),
            log: function (tags, data, timestamp, _internal) {
                server.log(tags, data, timestamp, _internal);
            },
            plugins: originalKbnServer.server.plugins
        }
    };

    return { kbnServer };
}

module.exports.migrateTenants=migrateTenants;
module.exports.migrateTenant=migrateTenant;
