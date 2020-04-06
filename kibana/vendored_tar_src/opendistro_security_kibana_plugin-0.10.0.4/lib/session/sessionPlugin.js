import MissingTenantError from "../auth/errors/missing_tenant_error";
import MissingRoleError from "../auth/errors/missing_role_error";
import filterAuthHeaders from '../auth/filter_auth_headers';

var Hoek = require('hoek');
var Joi = require('joi');

/**
 * Name of the cookie where we store additional session information, such as authInfo
 * @type {string}
 */
const storageCookieName = 'security_storage';

let internals = {};

internals.config = Joi.object({
    authType: Joi.string().allow(null),
    authHeaderName: Joi.string(),
    authenticateFunction: Joi.func(),
    validateAvailableTenants: Joi.boolean().default(true),
    validateAvailableRoles: Joi.boolean().default(true)
}).required();


const register = function (server, options) {
    let results = Joi.validate(options, internals.config);
    Hoek.assert(!results.error, results.error);

    let settings = results.value;
    let esconfig = server.config().get('elasticsearch');

    // @todo Don't register e.g. authenticate() when we have Kerberos or Proxy-Auth?
    server.ext('onPreAuth', function (request, h) {
        request.auth.securitySessionStorage = {

            /**
             * Tries to authenticate a user. If multitenancy is enabled, we also try to validate that the
             * user has at least one valid tenant
             * @param {object} credentials
             * @returns {Promise<*>}
             */
            authenticate: async function(credentials, options = {}) {
                try {
		    
		    let whitelistedHeadersAndValues = filterAuthHeaders(request.headers, esconfig.requestHeadersWhitelist);

                    // authResponse is an object with .session and .user
                    const authResponse = await settings.authenticateFunction(credentials, options, whitelistedHeadersAndValues);

                    return this._handleAuthResponse(credentials, authResponse);
                } catch(error) {
                    // Make sure we clear any existing cookies if something went wrong
                    this.clear();
                    throw error;
                }

            },


            authenticateWithHeaders: async function(headers, credentials = {}, options = {}) {
                try {
                    let user = await server.plugins.opendistro_security.getSecurityBackend().authenticateWithHeaders(headers);
                    let session = {
                        username: user.username,
                        credentials: credentials,
                        authType: settings.authType,
                        /**
                         * Used later to signal that we should not assign any specific auth header in AuthType
                         */
                        assignAuthHeader: false
                    };

                    let sessionTTL = server.config().get('opendistro_security.session.ttl')

                    if(sessionTTL) {
                        session.expiryTime = Date.now() + sessionTTL
                    }

                    const authResponse = {
                        session,
                        user
                    };

                    return this._handleAuthResponse(credentials, authResponse)
                } catch(error) {
                    // Make sure we clear any existing cookies if something went wrong
                    this.clear();
                    throw error;
                }
            },

            /**
             * Normalized response after an authentication
             * @param credentials
             * @param authResponse
             * @returns {*}
             * @private
             */
            _handleAuthResponse: function(credentials, authResponse) {
                // Make sure the user has a tenant that they can use
                if(settings.validateAvailableTenants && server.config().get("opendistro_security.multitenancy.enabled") && ! server.config().get("opendistro_security.multitenancy.tenants.enable_global")) {
                    let privateTenantEnabled = server.config().get("opendistro_security.multitenancy.tenants.enable_private");

                    let allTenants = authResponse.user.tenants;
                    if (allTenants != null && ! privateTenantEnabled) {
                        delete allTenants[authResponse.user.username]
                    }

                    if (allTenants == null || Object.keys(allTenants).length === 0) {
                        throw new MissingTenantError('No tenant available for this user, please contact your system administrator.')
                    }
                }

                // Validate that the user has at least one valid role
                if (settings.validateAvailableRoles && (!authResponse.user.roles || authResponse.user.roles.length === 0)) {
                    throw new MissingRoleError('No roles available for this user, please contact your system administrator.');
                }

                request.cookieAuth.set(authResponse.session);

                this.setAuthInfo(authResponse.user.username, authResponse.user.backendroles, authResponse.user.roles, authResponse.user.tenants, authResponse.user.selectedTenant);

                return authResponse;
            },

            /**
             * Returns the current auth type
             * @returns {void | null}
             */
            getAuthType: function() {
                return settings.authType;
            },

            getAuthHeaderName: function() {
                return settings.authHeaderName;
            },

            /**
             * Remember to call this in the correct lifecycle step. Calling this in onPreAuth will most likely return false because auth is not set up yet.
             * @returns {boolean}
             */
            isAuthenticated: function() {
                if (request.auth && request.auth.isAuthenticated) {
                    return true;
                }

                return false;
            },

            /**
             * Get the session credentials
             * @returns {*}
             */
            getSessionCredentials: function() {
                if (this.isAuthenticated()) {
                    return request.auth.credentials;
                }

                return null;
            },

            /**
             * Clears the cookies associated with the authenticated user
             */
            clear: function() {
                request.cookieAuth.clear();
                h.unstate(storageCookieName);
            },

            /**
             * Get the content of the storage cookie or, when key is defined, a part of it
             * @param key
             * @param whenMissing - Allows for a default value when the given key is not in the cookie
             * @returns {*}
             */
            getStorage: function(key, whenMissing = null) {
                let storage = request.state[storageCookieName];

                if (! storage) {
                    return whenMissing;
                }

                if (! key) {
                    return storage;
                }

                if (key && storage[key]) {
                    return storage[key];
                }

                return whenMissing;
            },

            /**
             * Store a value in the cookie
             * @param key
             * @param value
             */
            putStorage: function(key, value) {
                let storage = request.state[storageCookieName] || {};

                if (! key) {
                    // Bail if we don't have a key, the cookie should contain an object
                    return;
                }

                storage[key] = value;

                h.state(storageCookieName, storage);
            },

            /**
             * Clears the extra storage cookie only.
             * Use .clear to remove both the auth and the storage cookies
             *
             */

            /**
             * Clears the extra storage cookie only.
             * Use .clear to remove both the auth and the storage cookies
             *
             * @param key - Pass a key to only delete a part of the storage cookie.
             */
            clearStorage: function(key = null) {
                if (key === null) {
                    h.unstate(storageCookieName);
                    return;
                }

                let storage = this.getStorage();

                if (storage && storage[key]) {
                    delete storage[key];
                    h.state(storageCookieName, storage);
                }

            },

            /**
             * Store the result from the authinfo endpoint in the cookie.
             * We don't store everything at the moment.
             * @todo ask Jochen - custom_attribute_names could be too large for a cookie?
             *
             * @param user_name
             * @param backend_roles
             * @param roles
             * @param tenants
             * @param user_requested_tenant
             */
            setAuthInfo: function(user_name, backend_roles, roles, tenants, user_requested_tenant) {

                const authInfo = {
                    user_name,
                    backend_roles,
                    roles,
                    tenants,
                    user_requested_tenant
                };

                this.putStorage('authInfo', authInfo)
            },

            /**
             * The storage cookie is coupled to the auth cookie, so we try to validate it similar to
             * how we would validate the auth cookie
             * @returns {*}
             */
            validateStorageCookie: function() {
                let sessionStorage = this.getStorage();
                let authSession = this.getSessionCredentials();

                // If we have an existing storage session and an existing auth session,
                // we can assume that they are connected. We should validate that
                // the auth session hasn't expired
                // @todo Is this really necessary? We write the authInfo every time
                // that we login, and we may need to provide the authInfo even
                // if we don't have an auth session (Kerberos?) @Jochen
                if (sessionStorage && authSession) {
                    if (authSession.exp && authSession.exp < Math.floor(Date.now() / 1000)) {
                        sessionStorage = null;
                    }

                    if (authSession.expiryTime && authSession.expiryTime < Date.now()) {
                        sessionStorage = null;
                    }
                }

                return sessionStorage;
            },

            /**
             * Retrieves the authinfo from the storage cookie, if available.
             * If not available, we pass the request headers to the backend
             * and get the authinfo directly from there
             *
             * @returns {Promise<*>}
             */
            getAuthInfo: async function() {

                // See if we have the value in the cookie
                if (this.authType !== null) {
                    let sessionStorage = this.validateStorageCookie();
                    if (sessionStorage && sessionStorage.authInfo) {
                        return sessionStorage.authInfo;
                    }
                }

                try {
                    let authInfo = await server.plugins.opendistro_security.getSecurityBackend().authinfo(request.headers);
                    // Don't save the authInfo in the cookie for e.g. Kerberos and Proxy-Auth
                    if (this.authType !== null && this.isAuthenticated()) {
                        this.setAuthInfo(authInfo.user_name, authInfo.backend_roles, authInfo.roles, authInfo.tenants, authInfo.user_requested_tenant);
                    }

                    return authInfo;

                } catch (error) {
                    // Remove the storage cookie if something went wrong
                    if (this.authType !== null) {
                        h.unstate(storageCookieName);
                    }

                    throw error;
                }
            }
        };

        return h.continue;
    });

}


exports.plugin = {
    name: 'security-session-storage',
    register
};
