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

import Boom from 'boom';
import Joi from 'joi';
import indexTemplate from '../elasticsearch/setup_index_template';
import { migrateTenant } from './migrate_tenants';

module.exports = function (pluginRoot, server, kbnServer, APP_ROOT, API_ROOT) {

    const backend = server.plugins.opendistro_security.getSecurityBackend();
    const { setupIndexTemplate } = indexTemplate(this, server);
    const debugEnabled = server.config().get("opendistro_security.multitenancy.debug");

    server.route({
        method: 'POST',
        path: `${API_ROOT}/multitenancy/tenant`,
        handler: (request, h) => {

            var username = request.payload.username;
            var selectedTenant = request.payload.tenant;
            var prefs = backend.updateAndGetTenantPreferences(request, username, selectedTenant);

            request.auth.securitySessionStorage.putStorage('tenant', {
                selected: selectedTenant,
            });

            if (debugEnabled) {
                request.log(['info', 'security', 'tenant_POST'], selectedTenant);
            }

            return h.response(request.payload.tenant).state('security_preferences', prefs);
        }
    });

    server.route({
        method: 'GET',
        path: `${API_ROOT}/multitenancy/tenant`,
        handler: (request, h) => {
            let selectedTenant = request.auth.securitySessionStorage.getStorage('tenant', {}).selected;

            if (debugEnabled) {
                request.log(['info', 'security', 'tenant_GET'], selectedTenant);
            }

            return selectedTenant;
        }
    });

    server.route({
        method: 'GET',
        path: `${API_ROOT}/multitenancy/info`,
        handler: (request, h) => {
            let mtinfo = server.plugins.opendistro_security.getSecurityBackend().multitenancyinfo(request.headers);
            return mtinfo;
        }
    });

    server.route({
        method: 'POST',
        path: `${API_ROOT}/multitenancy/migrate/{tenantindex}`,
        handler: async (request, h) => {
            if (!request.params.tenantindex) {
                return h.response(Boom.badRequest, "Please provide a tenant index name.")
            }
            let forceMigration = false;
            if (request.query.force && request.query.force == "true") {
                forceMigration = true
            }
            let result = await migrateTenant(request.params.tenantindex, forceMigration, server);
            return result;
        }
    });

}; //end module
