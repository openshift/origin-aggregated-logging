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
import AuthenticationError from "../../errors/authentication_error";
import MissingRoleError from "../../errors/missing_role_error";
const Wreck = require('wreck');
const https = require('https');
const fs = require('fs');

export default class OpenId extends AuthType {

    constructor(pluginRoot, server, kbnServer, APP_ROOT, API_ROOT) {

        super(pluginRoot, server, kbnServer, APP_ROOT, API_ROOT);

        /**
         * The authType is saved in the auth cookie for later reference
         * @type {string}
         */
        this.type = 'openid';

        // support for self signed certificates: root ca and verify hostname
        const options = {};

        if (this.config.get('opendistro_security.openid.root_ca')) {
            options.ca = [ fs.readFileSync(this.config.get('opendistro_security.openid.root_ca')) ]
        }

        if (this.config.get('opendistro_security.openid.verify_hostnames') == false) {
            // do not check identity
            options.checkServerIdentity = function(host, cert) {}
        }

        if (options.ca || options.checkServerIdentity) {
            Wreck.agents.https = new https.Agent(options);
        }

        try {
            this.authHeaderName = this.config.get('opendistro_security.openid.header').toLowerCase();
        } catch(error) {
            this.kbnServer.status.yellow('No authorization header name defined for OpenId, using "authorization"');
            this.authHeaderName = 'authorization'
        }
    }

    async authenticate(credentials)  {
        // A "login" can happen when we have a token (as header or as URL parameter but no session,
        // or when we have an existing session, but the passed token does not match what's in the session.
        try {

            let user = await this.server.plugins.opendistro_security.getSecurityBackend().authenticateWithHeader(this.authHeaderName, credentials.authHeaderValue);
            let tokenPayload = {};
            try {
                tokenPayload = JSON.parse(Buffer.from(credentials.authHeaderValue.split('.')[1], 'base64').toString());
            } catch (error) {
                // Something went wrong while parsing the payload, but the user was authenticated correctly.
            }

            let session = {
                username: user.username,
                credentials: credentials,
                authType: this.type
            };

            if (tokenPayload.exp) {
                // The token's exp value trumps the config setting
                this.sessionKeepAlive = false;
                session.exp = parseInt(tokenPayload.exp, 10);
            } else if(this.sessionTTL) {
                session.expiryTime = Date.now() + this.sessionTTL
            }

            return {
                session,
                user
            };

        } catch (error) {
            throw error
        }
    }

    onUnAuthenticated(request, h, error) {

        // If we don't have any tenant we need to show the custom error page
        if (error instanceof MissingTenantError) {
            return h.redirect(this.basePath + '/customerror?type=missingTenant')
        } else if (error instanceof MissingRoleError) {
            return h.redirect(this.basePath + '/customerror?type=missingRole')
        } else if (error instanceof AuthenticationError) {
            return h.redirect(this.basePath + '/customerror?type=authError')
        }

        const nextUrl = this.getNextUrl(request);
        return h.redirect(`${this.basePath}/auth/openid/login?nextUrl=${nextUrl}`);
    }

    async setupRoutes() {
         try {
            const {response, payload} = await Wreck.get(this.config.get('opendistro_security.openid.connect_url'));

            const parsedPayload = JSON.parse(payload.toString());

            let endPoints = {
                authorization_endpoint: parsedPayload.authorization_endpoint,
                token_endpoint: parsedPayload.token_endpoint,
                end_session_endpoint: parsedPayload.end_session_endpoint || null
            };

            require('./routes')(this.pluginRoot, this.server, this.kbnServer, this.APP_ROOT, this.API_ROOT, endPoints);
         }catch (error) {
            if (error ||
                error.output.statusCode < 200 ||
                error.output.statusCode > 299) {
                throw new Error('Failed when trying to obtain the endpoints from your IdP');
            }
         }
    }
}