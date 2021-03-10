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

import {assign} from 'lodash';

export default function (pluginRoot, server, kbnServer, APP_ROOT, API_ROOT, authClass) {

    const config = server.config();
    const basePath = config.get('server.basePath');
    const global_enabled = config.get('opendistro_security.multitenancy.tenants.enable_global');
    const private_enabled = config.get('opendistro_security.multitenancy.tenants.enable_private');
    const preferredTenants = config.get('opendistro_security.multitenancy.tenants.preferred');
    const debugEnabled = config.get('opendistro_security.multitenancy.debug');
    const backend = server.plugins.opendistro_security.getSecurityBackend();

    const defaultSpaceId = 'default';

    server.ext('onPreAuth', async function (request, h) {

        // default is the tenant stored in the tenants cookie
        const storedSelectedTenant = request.auth.securitySessionStorage.getStorage('tenant', {}).selected;
        let selectedTenant = storedSelectedTenant;

        if (debugEnabled) {
            request.log(['info', 'security', 'tenant_storagecookie'], selectedTenant);
        }

        // check for tenant information in HTTP header. E.g. when using the saved objects API
        if(request.headers.securitytenant || request.headers.security_tenant) {
            selectedTenant = request.headers.securitytenant? request.headers.securitytenant : request.headers.security_tenant;

            if (debugEnabled) {
                request.log(['info', 'security', 'tenant_http_header'], selectedTenant);
            }

        }

        // check for tenant information in GET parameter. E.g. when using a share link. Overwrites the HTTP header.
        if (request.query && (request.query.security_tenant || request.query.securitytenant)) {
            selectedTenant = request.query.security_tenant? request.query.security_tenant : request.query.securitytenant;

            if (debugEnabled) {
                request.log(['info', 'security', 'tenant_url_param'], selectedTenant);
            }

        }

        // MT is only relevant for these paths
        if (!request.path.startsWith("/elasticsearch") && !request.path.startsWith("/api") && !request.path.startsWith("/app") && request.path != "/" && !selectedTenant) {
            return h.continue;
        }

        var response;

        try {
            if (authClass) {
                await authClass.assignAuthHeader(request);
            }

            response = await request.auth.securitySessionStorage.getAuthInfo(request.headers);
        } catch(error) {
            return h.continue;
        }

        // if we have a tenant, check validity and set it
        if (typeof selectedTenant !== 'undefined' && selectedTenant !== null) {
            selectedTenant = backend.validateTenant(response.user_name, selectedTenant, response.tenants, global_enabled, private_enabled);
        } else {
            // no tenant, choose configured, preferred tenant
            try {
                selectedTenant = backend.getTenantByPreference(request, response.user_name, response.tenants, preferredTenants, global_enabled, private_enabled);
            } catch(error) {
                // nothing
            }
        }

        if(selectedTenant != storedSelectedTenant) {
            // save validated tenant as preference
            let prefcookie = backend.updateAndGetTenantPreferences(request, response.user_name, selectedTenant);
            request.auth.securitySessionStorage.putStorage('tenant', {
                selected: selectedTenant
            });
            h.state('security_preferences', prefcookie);
        }

        if (debugEnabled) {
            request.log(['info', 'security', 'tenant_assigned'], selectedTenant);
        }

        if (selectedTenant != null) {
            assign(request.headers, {'securitytenant' : selectedTenant});
        }


        // Test for default space?
        if (config.has('xpack.spaces.enabled') && config.get('xpack.spaces.enabled') && (request.path === '/' || request.path.startsWith('/app'))) {

            // We can't add a default space for RO tenants at the moment
            if (selectedTenant && response.tenants[selectedTenant] === false) {
                return h.continue;
            }

            const spacesClient = server.plugins.spaces.spacesClient.getScopedClient(request);
            let defaultSpace = null;

            try {
                defaultSpace = await spacesClient.get(defaultSpaceId)
            } catch(error) {
                // Most likely not really an error, default space just not found
            }

            if (defaultSpace === null) {
                try {

                    if (selectedTenant && response.tenants[selectedTenant] === false) {
                        await addDefaultSpaceToReadOnlyTenant(server, spacesClient, request, backend, defaultSpaceId, selectedTenant);
                    } else {
                        await addDefaultSpaceToWriteTenant(server, spacesClient, defaultSpaceId);
                    }
                } catch(error) {
                    // We can't really recover from this error, so we'll just continue for now.
                    // The specific error should have been logged in the respective create method.
                }
            }
        }

        return h.continue;
    });
}


async function addDefaultSpaceToWriteTenant(server, spacesClient, defaultSpaceId) {
    try {
        await spacesClient.create({
            id: defaultSpaceId,
            name: 'Default',
            description: 'This is your default space!',
            color: '#00bfb3',
            _reserved: true
        });
        return true;
    } catch(error) {
        server.log(['security', 'error'], `An error occurred while creating a default space`);
        throw error;
    }

}

async function addDefaultSpaceToReadOnlyTenant(server, spacesClient, request, backend, defaultSpaceId, tenantName) {
    try {
        let tenantInfo = await backend.getTenantInfoWithInternalUser();

        let indexName = null;
        for (let tenantIndexName in tenantInfo) {
            if (tenantInfo[tenantIndexName] === tenantName) {
                indexName = tenantIndexName;
            }
        }

        // We have one known issue here. If a read only tenant is completely, the index will not yet have been created.
        // Hence, we won't retrieve an index name for that tenant.
        if (!indexName) {
            server.log(['security', 'error'], `Could not find the index name for the tenant while creating a default space for a read only tenant. The tenant is probably empty.`);
            throw new Error('Could not find the index name for the tenant');
        }

        // Call elasticsearch directly without using the Saved Objects Client
        const adminCluster = server.plugins.elasticsearch.getCluster('admin');
        const { callWithRequest } = adminCluster;

        const clientParams = {
            id: `space:${defaultSpaceId}`, // Should this be the default space id?
            type: 'doc',
            index: indexName,
            refresh: 'wait_for',
            body: {
                space: {
                    name: 'Default',
                    description: 'This is your default space',
                    color: '#00bfb3',
                    _reserved: true
                },
                type: 'space',
                updated_at: new Date().toISOString(),
            }
        };

        // Create the space
        callWithRequest(request, 'create', clientParams);

    } catch (error) {
        server.log(['security', 'error'], `An error occurred while creating a default space for a read only tenant`);
        throw error;
    }
}
