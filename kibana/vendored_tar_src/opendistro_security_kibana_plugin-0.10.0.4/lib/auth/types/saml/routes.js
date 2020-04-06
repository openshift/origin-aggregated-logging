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
import {parseNextUrl} from '../../parseNextUrl'
import MissingTenantError from "../../errors/missing_tenant_error";
import AuthenticationError from "../../errors/authentication_error";

module.exports = function (pluginRoot, server, kbnServer, APP_ROOT, API_ROOT) {

    const AuthenticationError = pluginRoot('lib/auth/errors/authentication_error');
    const config = server.config();
    const basePath = config.get('server.basePath');
    const customErrorApp = server.getHiddenUiAppById('security-customerror');

    const routesPath = '/auth/saml/';

    /**
     * The login page.
     */
    server.route({
        method: 'GET',
        path: `${APP_ROOT}${routesPath}login`,
        options: {
            auth: false
        },

        async handler(request, h) {
            if (request.auth.isAuthenticated) {
                return h.redirect(basePath + '/app/kibana');
            }

            let nextUrl = null;
            if (request.url && request.url.query && request.url.query.nextUrl) {
                nextUrl = parseNextUrl(request.url.query.nextUrl, basePath);
            }

            // Grab the request for SAML
            try {
                const samlHeader = await server.plugins.opendistro_security.getSecurityBackend().getSamlHeader()
                request.auth.securitySessionStorage.putStorage('temp-saml', {
                    requestId: samlHeader.requestId,
                    nextUrl: nextUrl
                });

                return h.redirect(samlHeader.location).takeover();
            } catch (error) {
                return h.redirect(basePath + '/customerror?type=samlConfigError');
            }
        }

    });

    /**
     * The page that the IdP redirects to after a successful SP-initiated login
     */
    server.route({
        method: 'POST',
        path: `${APP_ROOT}/_opendistro/_security/saml/acs`,
        options: {
            auth: false
        },
        handler: async (request, h) => {

            let storedRequestInfo = request.auth.securitySessionStorage.getStorage('temp-saml', {});
            request.auth.securitySessionStorage.clearStorage('temp-saml');
            if (! storedRequestInfo.requestId) {
                return h.redirect(basePath + '/customerror?type=samlAuthError');
            }

            try {
                let credentials = await server.plugins.opendistro_security.getSecurityBackend().authtoken(storedRequestInfo.requestId || null, request.payload.SAMLResponse);
                let {user} = await request.auth.securitySessionStorage.authenticate({
                    authHeaderValue: credentials.authorization
                });
                let nextUrl = storedRequestInfo.nextUrl;
                if (nextUrl) {
                    nextUrl = parseNextUrl(nextUrl, basePath);
                    return h.redirect(nextUrl);
                }

                return h.redirect(basePath + '/app/kibana');

            } catch (error) {
                if (error instanceof AuthenticationError) {
                    return h.redirect(basePath + '/customerror?type=samlAuthError');
                } else if (error instanceof MissingTenantError) {
                    return h.redirect(basePath + '/customerror?type=missingTenant');
                } else {
                    return h.redirect(basePath + '/customerror?type=samlAuthError');
                }
            }
        }
    });

    /**
     * The page that the IdP redirects to after a successful IdP-initiated login
     */
    server.route({
        method: 'POST',
        path: `${APP_ROOT}/_opendistro/_security/saml/acs/idpinitiated`,
        options: {
            auth: false
        },
        handler: async (request, h) => {

            try {
                const acsEndpoint = `${APP_ROOT}/_opendistro/_security/saml/acs/idpinitiated`;
                let credentials = await server.plugins.opendistro_security.getSecurityBackend().authtoken(null, request.payload.SAMLResponse, acsEndpoint);

                let {user} = await request.auth.securitySessionStorage.authenticate({
                    authHeaderValue: credentials.authorization
                });

                return h.redirect(basePath + '/app/kibana');

            } catch (error) {
                if (error instanceof AuthenticationError) {
                    return h.redirect(basePath + '/customerror?type=samlAuthError');
                } else if (error instanceof MissingTenantError) {
                    return h.redirect(basePath + '/customerror?type=missingTenant');
                } else {
                    return h.redirect(basePath + '/customerror?type=samlAuthError');
                }
            }
        }

    });

    /**
     * The custom error page.
     */
    server.route({
        method: ['GET', 'POST'],
        path:  `${APP_ROOT}/_opendistro/_security/saml/logout`,
        handler(request, h) {
            return h.redirect(`${APP_ROOT}/customerror?type=samlLogoutSuccess`);
        },
        options: {
            auth: false
        }
    });

    /**
     * The custom error page.
     */
    server.route({
        method: 'GET',
        path:  `${APP_ROOT}/customerror`,
        handler(request, h) {
            return h.renderAppWithDefaultConfig(customErrorApp);
        },
        options: {
            auth: false
        }
    });

    /**
     * Logout
     */
    server.route({
        method: 'POST',
        path: `${API_ROOT}/auth/logout`,
        handler: async(request, h) => {

            const cookieName = config.get('opendistro_security.cookie.name');
            let authInfo = null;

            try {
                let authHeader = {
                    [request.auth.securitySessionStorage.getAuthHeaderName()]: request.state[cookieName].credentials.authHeaderValue
                };
                authInfo = await server.plugins.opendistro_security.getSecurityBackend().authinfo(authHeader);
            } catch(error) {
                // Not much we can do here, so we'll just fall back to the login page if we don't get an sso_logout_url
            }

            request.auth.securitySessionStorage.clear();
            const redirectURL = (authInfo && authInfo.sso_logout_url) ? authInfo.sso_logout_url : `${APP_ROOT}/customerror?type=samlLogoutSuccess`;

            return {redirectURL};
        },
        options: {
            auth: false
        }
    });

}; //end module
