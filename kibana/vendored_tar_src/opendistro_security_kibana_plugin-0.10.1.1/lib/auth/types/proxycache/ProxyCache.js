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

import AuthType from "../AuthType";
import MissingTenantError from "../../errors/missing_tenant_error";
import SessionExpiredError from "../../errors/session_expired_error";
import {parse, format} from 'url';
import MissingRoleError from "../../errors/missing_role_error";
import {parseLoginEndpoint} from "./parse_login_endpoint";

export default class ProxyCache extends AuthType {

    constructor(pluginRoot, server, kbnServer, APP_ROOT, API_ROOT) {

        super(pluginRoot, server, kbnServer, APP_ROOT, API_ROOT);

        /**
         * The authType is saved in the auth cookie for later reference
         * @type {string}
         */
        this.type = 'proxycache';

        /**
         * The header that identifies the user
         */
        this.userHeaderName = this.config.get('opendistro_security.proxycache.user_header').toLowerCase();

        /**
         * The header that identifies the user's role(s). Optional.
         */
        this.rolesHeaderName = this.config.get('opendistro_security.proxycache.roles_header').toLowerCase();
    }

    /**
     * Detect authorization header value, either as an http header or as a query parameter
     * @param request
     * @param sessionCredentials
     * @returns {*}
     */
    detectAuthHeaderCredentials(request, sessionCredentials = null) {

        // The point of ProxyCache is that we only have headers on the first request.
        // In other words, if we already have a session, we don't need to check the headers.
        if (sessionCredentials !== null) {
            return null;
        }

        if (request.headers[this.userHeaderName]) {
            const authHeaderValues = {
                [this.userHeaderName]: request.headers[this.userHeaderName],
                'x-forwarded-for': request.headers['x-forwarded-for']
            };

            // The roles header is optional
            if (request.headers[this.rolesHeaderName]) {
                authHeaderValues[this.rolesHeaderName] = request.headers[this.rolesHeaderName];
            }

            return authHeaderValues;

        } else if (request.headers[this.authHeaderName]) {
            return {
                [this.authHeaderName]: request.headers[this.authHeaderName]
            }
        }

        // We still need to support basic auth for Curl etc.
        return null;
    }

    /**
     * Returns the auth header(s) needed for the Security backend
     * @param session
     * @returns {*}
     */
    getAuthHeader(session) {
        if (! session.credentials) {
            return false;
        }

        if (session.credentials[this.userHeaderName]) {
            return {
                [this.userHeaderName]: session.credentials[this.userHeaderName],
                [this.rolesHeaderName]: session.credentials[this.rolesHeaderName]
            }
        } else if (session.credentials[this.authHeaderName]) {
            return {
                [this.authHeaderName]: session.credentials[this.authHeaderName]
            }
        }

        return false;
    }

    async authenticate(credentialHeaders) {
        try {
            let user = await this.server.plugins.opendistro_security.getSecurityBackend().authenticateWithHeaders(credentialHeaders, credentialHeaders);

            let session = {
                username: user.username,
                credentials: credentialHeaders,
                authType: this.type
            };

            if(this.sessionTTL) {
                session.expiryTime = Date.now() + this.sessionTTL
            }

            return {
                session,
                user
            };

        } catch (error) {
            throw error;
        }
    }

    onUnAuthenticated(request, h, error) {
        if (error instanceof MissingTenantError) {
            return h.redirect(this.basePath + '/customerror?type=missingTenant');
        } else if (error instanceof MissingRoleError) {
            return h.redirect(this.basePath + '/customerror?type=missingRole');
        } else {
            // The customer may use a login endpoint, to which we can redirect
            // if the user isn't authenticated.
            let loginEndpoint = this.config.get('opendistro_security.proxycache.login_endpoint');
            if (loginEndpoint) {
                try {
                    const redirectUrl = parseLoginEndpoint(loginEndpoint, request);
                    return h.redirect(redirectUrl);
                } catch(error) {
                    this.server.log(['error', 'security'], 'An error occured while parsing the opendistro_security.proxycache.login_endpoint value');
                    return h.redirect(this.basePath + '/customerror?type=proxycacheAuthError');
                }
            } else if (error instanceof SessionExpiredError) {
                return h.redirect(this.basePath + '/customerror?type=sessionExpired');
            } else {
                return h.redirect(this.basePath + '/customerror?type=proxycacheAuthError');
            }
        }
    }

    setupRoutes() {
        require('./routes')(this.pluginRoot, this.server, this.kbnServer, this.APP_ROOT, this.API_ROOT);
    }

    addAdditionalAuthHeaders(request, authHeader) {
        // for proxy cache mode, make it possible to assign the proxy ip,
        // usually as x-forwarded-for header. Only if no headers are already present
        let existingProxyHeaders = request.headers[this.config.get('opendistro_security.proxycache.proxy_header')];
        // do not overwrite existing headers from existing proxy
        if (existingProxyHeaders) {
            return;
        }

        let remoteIP = request.info.remoteAddress;
        let proxyIP = this.config.get('opendistro_security.proxycache.proxy_header_ip');
        authHeader[this.config.get('opendistro_security.proxycache.proxy_header')] = remoteIP+","+proxyIP
    }

}