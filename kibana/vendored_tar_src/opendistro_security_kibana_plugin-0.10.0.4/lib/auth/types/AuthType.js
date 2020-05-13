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

import { assign } from 'lodash';
import Boom from 'boom';
import InvalidSessionError from "../errors/invalid_session_error";
import SessionExpiredError from "../errors/session_expired_error";

export default class AuthType {

    constructor(pluginRoot, server, kbnServer, APP_ROOT, API_ROOT) {
        this.pluginRoot = pluginRoot;
        this.server = server;
        this.kbnServer = kbnServer;
        this.APP_ROOT = APP_ROOT;
        this.API_ROOT = API_ROOT;
        this.config = server.config();

        this.basePath = this.config.get('server.basePath');
        this.unauthenticatedRoutes = this.config.get('opendistro_security.auth.unauthenticated_routes');

        this.sessionTTL = this.config.get('opendistro_security.session.ttl');
        this.sessionKeepAlive = this.config.get('opendistro_security.session.keepalive');

        /**
         * The authType is saved in the auth cookie for later reference
         * @type {string}
         */
        this.type = null;

        /**
         * Tells the sessionPlugin whether or not to validate the number of tenants when authenticating
         * @type {boolean}
         */
        this.validateAvailableTenants = true;

        /**
         * The name of the header were we look for an authorization value.
         * This should most likely be set in the subclass depending on a config value.
         * @type {string}
         */
        this.authHeaderName = 'authorization';

         /**
         * This is a workaround for keeping track of what caused hapi-auth-cookie's validateFunc to fail.
         * There seems to be an issue with how the plugin checks the thrown error and instead of passing
         * it on, it throws its own error.
         *
         * @type {null}
         * @private
         */
        this._cookieValidationError;
    }

    async init() {
        this.setupStorage();
        // Setting up routes before the auth scheme, mainly for the case where something goes wrong
        // when OpenId tries to get the connect_url
        await this.setupRoutes();
        this.setupAuthScheme();
    }

    setupStorage() {
        this.server.register({
            plugin: this.pluginRoot('lib/session/sessionPlugin'),
            options: {
                authType: this.type,
                authHeaderName: this.authHeaderName,
                authenticateFunction: this.authenticate.bind(this),
                validateAvailableTenants: this.validateAvailableTenants
            }
        })
    }

    getCookieConfig() {
        const cookieConfig = {
            password: this.config.get('opendistro_security.cookie.password'),
            cookie: this.config.get('opendistro_security.cookie.name'),
            isSecure: this.config.get('opendistro_security.cookie.secure'),
            validateFunc: this.sessionValidator(this.server),
            clearInvalid: true,
            ttl: this.config.get('opendistro_security.cookie.ttl'),
            isSameSite: this.config.get('opendistro_security.cookie.isSameSite')
        };

        if (this.config.get('opendistro_security.cookie.domain')) {
            cookieConfig["domain"] = this.config.get('opendistro_security.cookie.domain');
        }


        return cookieConfig;
    }

    /**
     * Returns the auth header needed for the Security backend
     * @param session
     * @returns {*}
     */
    getAuthHeader(session) {
        if (session.credentials && session.credentials.authHeaderValue) {
            return {
                [this.authHeaderName]: session.credentials.authHeaderValue
            }
        }

        return false;
    }

    /**
     * Checks if we have an authorization header.
     *
     * Pass the existing session credentials to compare with the authorization header.
     *
     * @param request
     * @param sessionCredentials
     * @returns {object|null} - credentials for the authentication
     */
    detectAuthHeaderCredentials(request, sessionCredentials = null) {

        if (request.headers[this.authHeaderName]) {
            const authHeaderValue = request.headers[this.authHeaderName];

            // If we have sessionCredentials AND auth headers we need to check if they are the same.
            if (sessionCredentials !== null && sessionCredentials.authHeaderValue === authHeaderValue) {
                // The auth header credentials are the same as those in the session,
                // no need to return new credentials so we're just nulling the token here
                return null;
            }

            return {
                authHeaderValue: authHeaderValue
            }
        }

        return null;
    }

    authenticate(credentials) {
        throw new Error('The authenticate method must be implemented by the sub class');
    }

    onUnAuthenticated(request, h) {
        throw new Error('The onUnAuthenticated method must be implemented by the sub class');
    }

    /**
     * A helper for generating the correct nextUrl.
     * Spaces manipulates the URL for non default
     * spaces, and that change is not reflected
     * in request.url.path
     * @param request
     * @returns {string}
     */
    getNextUrl(request) {
        return encodeURIComponent(request.getBasePath() + request.url.path);
    }

    setupRoutes() {
        throw new Error('The getAuthHeader method must be implemented by the sub class');
    }

    setupAuthScheme() {
        this.server.auth.scheme('security_access_control_scheme', (server, options) => ({
            authenticate: async(request, h) => {
                let credentials = null;
                // let configured routes that are not under our control pass,
                // for example /api/status to check Kibana status without a logged in user
                if (this.unauthenticatedRoutes.includes(request.path)) {
                    credentials = this.server.plugins.opendistro_security.getSecurityBackend().getServerUser();
                    return h.authenticated({credentials});
                };

                try {
                    credentials = await this.server.auth.test('security_access_control_cookie', request);
                    return h.authenticated({credentials})
                 } catch(error) {
                    if (this._cookieValidationError) {
                        return this.onUnAuthenticated(request, h, this._cookieValidationError).takeover();
                    }

                    let authHeaderCredentials = this.detectAuthHeaderCredentials(request);
                    if (authHeaderCredentials) {
                        try {
                            let {session} = await request.auth.securitySessionStorage.authenticate(authHeaderCredentials);
                            // Returning the session equals setting the values with hapi-auth-cookie@set()
                            return h.authenticated({
                                // Watch out here - hapi-auth-cookie requires us to send back an object with credentials
                                // as a key. Otherwise other values than the credentials will be overwritten
                                credentials: session
                                });
                            } catch (authError) {
                                return this.onUnAuthenticated(request, h, authError).takeover();
                            }

                    if (request.headers) {
                        // If the session has expired, we may receive ajax requests that can't handle a 302 redirect.
                        // In this case, we trigger a 401 and let the interceptor handle the redirect on the client side.
                        if ((request.headers.accept && request.headers.accept.split(',').indexOf('application/json') > -1)
                          || (request.headers['content-type'] && request.headers['content-type'].indexOf('application/json') > -1)) {
                            return h.response({message: 'Session expired', redirectTo: 'login'})
                              .code(401)
                              .takeover();
                        }
                    }

                    }

                 }
                 return this.onUnAuthenticated(request, h).takeover();
            }
        }));

        // Activates hapi-auth-cookie for ALL routes, unless
        // a) the route is listed in "unauthenticatedRoutes" or
        // b) the auth option in the route definition is explicitly set to false
        this.server.auth.strategy('security_access_control', 'security_access_control_scheme', this.getCookieConfig());
        this.server.auth.strategy('security_access_control_cookie', 'cookie', this.getCookieConfig());

         this.server.auth.default({
            mode: 'required', // @todo Investigate best mode here
            strategy: 'security_access_control' // This seems to be the only way to apply the strategy to ALL routes, even those defined before we add the strategy.
         });

    }

    /**
     * If a session auth cookie exists, the sessionValidator is called to validate the content
     * @param server
     * @returns {validate}
     */
    sessionValidator(server) {

        let validate = async(request, session) => {
            this._cookieValidationError = null;

            if (session.authType !== this.type) {
                this._cookieValidationError = new InvalidSessionError('Invalid session');
                request.auth.securitySessionStorage.clearStorage();
                return {valid: false};
            }

            // Check if we have auth header credentials set that are different from the session credentials
            let differentAuthHeaderCredentials = this.detectAuthHeaderCredentials(request, session.credentials);
            if (differentAuthHeaderCredentials) {
                try {
                    let authResponse = await request.auth.securitySessionStorage.authenticate(differentAuthHeaderCredentials);
                    return {valid: true, credentials: authResponse.session};
                } catch(error) {
                    request.auth.securitySessionStorage.clearStorage();
                    return {valid: false};
                }
            }

            // If we are still here, we need to compare the expiration time
            // JWT's .exp is denoted in seconds, not milliseconds.
            if (session.exp && session.exp < Math.floor(Date.now() / 1000)) {
                this._cookieValidationError = new SessionExpiredError('Session expired');
                request.auth.securitySessionStorage.clearStorage();
                return {valid: false};
            } else if (!session.exp && this.sessionTTL) {
                if (!session.expiryTime || session.expiryTime < Date.now()) {
                    this._cookieValidationError = new SessionExpiredError('Session expired');
                    request.auth.securitySessionStorage.clearStorage();
                    return {valid: false};
                }

                if (this.sessionKeepAlive) {
                    session.expiryTime = Date.now() + this.sessionTTL;
                    // According to the documentation, returning the session in the cookie
                    // should be equivalent to calling request.auth.session.set(),
                    // but it seems like the cookie's browser lifetime isn't updated.
                    // @todo TEST IF THIS HAS BEEN FIXED IN HAPI-AUTH-COOKIE
                    request.cookieAuth.set(session);
                }
            }

            return {valid: true, credentials: session};

        };

        return validate;
    }

    /**
     * Add credential headers to the passed request.
     * @param request
     */
    async assignAuthHeader(request) {

        if (! request.headers[this.authHeaderName]) {

            let session = request.state[this.config.get('opendistro_security.cookie.name')];

            if (session) {
                const sessionValidator = this.sessionValidator();
                try {
                    const sessionValidationResult = await sessionValidator(request, session);
                    if (sessionValidationResult.valid) {
                        session = sessionValidationResult.credentials;
                    } else {
                        session = false;
                    }
                } catch(error) {
                    this.server.log(['security', 'error'], `An error occurred while computing auth headers, clearing session: ${error}`);
                }
            }


            if (session && session.credentials) {
                try {
                    let authHeader = this.getAuthHeader(session);
                    if (authHeader !== false) {
                        this.addAdditionalAuthHeaders(request, authHeader);
                        assign(request.headers, authHeader);
                    }
                } catch (error) {
                    this.server.log(['security', 'error'], `An error occurred while computing auth headers, clearing session: ${error}`);
                    request.auth.securitySessionStorage.clear();
                    throw error;

                }
            }
        }
    }

    /**
     * Called on each authenticated request.
     * Used to add the credentials header to the request.
     */
    registerAssignAuthHeader() {
        this.server.ext('onPreAuth', (request, h) => {
            try {
                this.assignAuthHeader(request);
            } catch(error) {
                return h.redirect(this.basePath + '/customerror?type=authError');
            }

            return h.continue;
        });
    }


    /**
     * Method for adding additional auth type specific authentication headers.
     * Override this in the auth type for type specific headers.
     * @param request
     * @param authHeader
     */
    addAdditionalAuthHeaders(request, authHeader) {

    }


}