const pluginRoot = require('requirefrom')('');
import { resolve, join, sep } from 'path';
import { has } from 'lodash';
import indexTemplate from './lib/elasticsearch/setup_index_template';
import { migrateTenants } from './lib/multitenancy/migrate_tenants';
import { version as opendistro_security_version } from './package.json';

export default function (kibana) {

    let APP_ROOT;
    let API_ROOT;
    let authenticationBackend;
    let securityConfiguration;


    return new kibana.Plugin({
        name: 'opendistro_security',
        id: 'opendistro_security',
        require: ['kibana', 'elasticsearch'],

        config: function (Joi) {
            var obj = Joi.object({
                enabled: Joi.boolean().default(true),
                allow_client_certificates: Joi.boolean().default(false),
                readonly_mode: Joi.object().keys({
                    roles: Joi.array().default([]),
                }).default(),
                xff: Joi.object().keys({
                    enabled: Joi.boolean().default(false),
                }).default(),
                cookie: Joi.object().keys({
                    secure: Joi.boolean().default(false),
                    name: Joi.string().default('security_authentication'),
                    password: Joi.string().min(32).default('security_cookie_default_password'),
                    ttl: Joi.number().integer().min(0).default(60 * 60 * 1000),
                    domain: Joi.string(),
                    isSameSite: Joi.valid('Strict', 'Lax').allow(false).default(false),
                }).default(),
                session: Joi.object().keys({
                    ttl: Joi.number().integer().min(0).default(60 * 60 * 1000),
                    keepalive: Joi.boolean().default(true),
                }).default(),
                auth: Joi.object().keys({
                    type: Joi.string().valid(['', 'basicauth', 'jwt', 'openid', 'saml', 'proxy', 'kerberos', 'proxycache']).default(''),
                    anonymous_auth_enabled: Joi.boolean().default(false),
                    unauthenticated_routes: Joi.array().default(["/api/status"]),
                    logout_url: Joi.string().allow('').default(''),
                }).default(),
                basicauth: Joi.object().keys({
                    enabled: Joi.boolean().default(true),
                    unauthenticated_routes: Joi.array().default(["/api/status"]),
                    forbidden_usernames: Joi.array().default([]),
                    header_trumps_session: Joi.boolean().default(false),
                    alternative_login: Joi.object().keys({
                        headers: Joi.array().default([]),
                        show_for_parameter: Joi.string().allow('').default(''),
                        valid_redirects: Joi.array().default([]),
                        button_text: Joi.string().default('Login with provider'),
                        buttonstyle: Joi.string().allow('').default("")
                    }).default(),
                    loadbalancer_url: Joi.string().allow('', null).default(null),
                    login: Joi.object().keys({
                        title: Joi.string().allow('').default('Please login to Kibana'),
                        subtitle: Joi.string().allow('').default('If you have forgotten your username or password, please ask your system administrator'),
                        showbrandimage: Joi.boolean().default(true),
                        brandimage: Joi.string().default("/plugins/opendistro_security/assets/open_distro_for_elasticsearch_logo_h.svg"),
                        buttonstyle: Joi.string().allow('').default("")
                    }).default(),
                }).default(),
                multitenancy: Joi.object().keys({
                    enabled: Joi.boolean().default(false),
                    show_roles: Joi.boolean().default(false),
                    enable_filter: Joi.boolean().default(false),
                    debug: Joi.boolean().default(false),
                    tenants: Joi.object().keys({
                        enable_private: Joi.boolean().default(true),
                        enable_global: Joi.boolean().default(true),
                        preferred: Joi.array(),
                    }).default(),
                }).default(),
                configuration: Joi.object().keys({
                    enabled: Joi.boolean().default(true)
                }).default(),
                accountinfo: Joi.object().keys({
                    enabled: Joi.boolean().default(false)
                }).default(),
                openid: Joi.object().keys({
                    connect_url: Joi.string(),
                    header: Joi.string().default('Authorization'),
                    client_id: Joi.string(),
                    client_secret: Joi.string().allow('').default(''),
                    scope: Joi.string().default('openid profile email address phone'),
                    base_redirect_url: Joi.string().allow('').default(''),
                    logout_url: Joi.string().allow('').default(''),
                    root_ca: Joi.string().allow('').default(''),
                    verify_hostnames: Joi.boolean().default(true)
                }).default().when('auth.type', {
                    is: 'openid',
                    then: Joi.object({
                        client_id: Joi.required(),
                        connect_url: Joi.required()
                    })
                }),
                proxycache: Joi.object().keys({
                    user_header: Joi.string(),
                    roles_header: Joi.string(),
                    proxy_header: Joi.string().default('x-forwarded-for'),
                    proxy_header_ip: Joi.string(),
                    login_endpoint: Joi.string().allow('', null).default(null),
                }).default().when('auth.type', {
                    is: 'proxycache',
                    then: Joi.object({
                        user_header: Joi.required(),
                        roles_header: Joi.required(),
                        proxy_header_ip: Joi.required()
                    })
                }),
                jwt: Joi.object().keys({
                    enabled: Joi.boolean().default(false),
                    login_endpoint: Joi.string(),
                    url_param: Joi.string().default('authorization'),
                    header: Joi.string().default('Authorization')
                }).default()
            }).default();
            return obj;
        },

        deprecations: function () {
            return [
                (settings, log) => {
                    if (has(settings, 'basicauth.enabled')) {
                        log('Config key "opendistro_security.basicauth.enabled" is deprecated. Please use "opendistro_security.auth.type" instead.');
                    }

                    if (has(settings, 'jwt.enabled')) {
                        log('Config key "opendistro_security.jwt.enabled" is deprecated. Please use "opendistro_security.auth.type" instead.');
                    }
                }
            ];
        },

        uiExports: {
            hacks: [
                'plugins/opendistro_security/chrome/readonly/enable_readonly',
                'plugins/opendistro_security/chrome/multitenancy/enable_multitenancy',
                'plugins/opendistro_security/chrome/logout_button',
                'plugins/opendistro_security/chrome/configuration/enable_configuration',
                'plugins/opendistro_security/services/access_control',
                'plugins/opendistro_security/customizations/enable_customizations.js'
            ],
            replaceInjectedVars: async function(originalInjectedVars, request, server) {
                const authType = server.config().get('opendistro_security.auth.type');
                // Make sure securityDynamic is always available to the frontend, no matter what
                // Remember that these values are only updated on page load.
                let securityDynamic = {};
                let userInfo = null;

                try {
                    // If the user is authenticated, just get the regular values
                    if(request.auth.securitySessionStorage.isAuthenticated()) {
                        let sessionCredentials = request.auth.securitySessionStorage.getSessionCredentials();
                        userInfo = {
                            username: sessionCredentials.username,
                            isAnonymousAuth: sessionCredentials.isAnonymousAuth
                        };
                    } else if (['', 'kerberos', 'proxy'].indexOf(authType) > -1) {
                        // We should be able to use this with kerberos and proxy too
                        try {
                            let authInfo = await request.auth.securitySessionStorage.getAuthInfo();
                            userInfo = {
                                username: authInfo.user_name
                            };
                        } catch(error) {
                            // Not authenticated, so don't do anything
                        }
                    }

                    if (userInfo) {
                        securityDynamic.user = userInfo;
                    }
                } catch (error) {
                    // Don't to anything here.
                    // If there's an error, it's probably because x-pack security is enabled.
                }



                if(server.config().get('opendistro_security.multitenancy.enabled')) {
                    let currentTenantName = 'global';
                    let currentTenant = '';
                    if (typeof request.headers['securitytenant'] !== 'undefined') {
                        currentTenant = request.headers['securitytenant'];
                    } else if (request.headers['security_tenant'] !== 'undefined') {
                        currentTenant = request.headers['security_tenant'];
                    }

                    currentTenantName = currentTenant;

                    if (currentTenant === '') {
                        currentTenantName = 'global';
                    } else if (currentTenant === '__user__') {
                        currentTenantName = 'private';
                    }

                    securityDynamic.multiTenancy = {
                        currentTenantName: currentTenantName,
                        currentTenant: currentTenant
                    };
                }

                return {
                    ...originalInjectedVars,
                    securityDynamic
                }
            },
            apps: [
                {
                    id: 'security-login',
                    title: 'Login',
                    main: 'plugins/opendistro_security/apps/login/login',
                    hidden: true,
                    auth: false
                },
                {
                    id: 'security-customerror',
                    title: 'CustomError',
                    main: 'plugins/opendistro_security/apps/customerror/customerror',
                    hidden: true,
                    auth: false
                },
                {
                    id: 'security-multitenancy',
                    title: 'Tenants',
                    main: 'plugins/opendistro_security/apps/multitenancy/multitenancy',
                    hidden: false,
                    auth: true,
                    order: 9010,
                    icon: 'plugins/opendistro_security/assets/networking.svg',
                    linkToLastSubUrl: false,
                    url: '/app/security-multitenancy#/'
                },
                {
                    id: 'security-accountinfo',
                    title: 'Account',
                    main: 'plugins/opendistro_security/apps/accountinfo/accountinfo',
                    hidden: false,
                    auth: true,
                    order: 9020,
                    icon: 'plugins/opendistro_security/assets/info.svg',
                    linkToLastSubUrl: false,
                    url: '/app/security-accountinfo#/'
                },
                {
                    id: 'security-configuration',
                    title: 'Security',
                    main: 'plugins/opendistro_security/apps/configuration/configuration',
                    order: 9009,
                    auth: true,
                    icon: 'plugins/opendistro_security/assets/opendistro_security.svg',
                    linkToLastSubUrl: false,
                    url: '/app/security-configuration#/'
                }
            ],
            chromeNavControls: [
                'plugins/opendistro_security/chrome/btn_logout/btn_logout.js'
            ]
            ,
            injectDefaultVars(server, options) {
                options.multitenancy_enabled = server.config().get('opendistro_security.multitenancy.enabled');
                options.accountinfo_enabled = server.config().get('opendistro_security.accountinfo.enabled');
                options.basicauth_enabled = server.config().get('opendistro_security.basicauth.enabled');
                options.kibana_index = server.config().get('kibana.index');
                options.kibana_server_user = server.config().get('elasticsearch.username');
                options.opendistro_security_version = opendistro_security_version;

                return options;
            }

        },

        async init(server, options) {

            APP_ROOT = '';
            API_ROOT = `${APP_ROOT}/api/v1`;
            const config = server.config();

            // If X-Pack is installed it needs to be disabled for Security to run.
            try {
                let xpackInstalled = false;
                Object.keys(server.plugins).forEach((plugin) => {
                    if (plugin.toLowerCase().indexOf('xpack') > -1) {
                        xpackInstalled = true;
                    }
                });

                if (xpackInstalled && config.get('xpack.security.enabled') !== false) {
                    // It seems like X-Pack is installed and enabled, so we show an error message and then exit.
                    this.status.red("X-Pack Security needs to be disabled for Security to work properly. Please set 'xpack.security.enabled' to false in your kibana.yml");
                    return false;
                }
            } catch (error) {
                server.log(['error', 'security'], `An error occurred while making sure that X-Pack isn't enabled`);
            }


            // all your routes are belong to us
            require('./lib/auth/routes_authinfo')(pluginRoot, server, this, APP_ROOT, API_ROOT);

            // provides authentication methods against Security
            const BackendClass = pluginRoot(`lib/backend/opendistro_security`);
            const securityBackend = new BackendClass(server, server.config);
            server.expose('getSecurityBackend', () => securityBackend);

            // provides configuration methods against Security
            const ConfigurationBackendClass = pluginRoot(`lib/configuration/backend/opendistro_security_configuration_backend`);
            const securityConfigurationBackend = new ConfigurationBackendClass(server, server.config);
            server.expose('getSecurityConfigurationBackend', () => securityConfigurationBackend);

            let authType = config.get('opendistro_security.auth.type');
            let authClass = null;

            // For legacy code
            if (! authType) {
                if (config.get('opendistro_security.basicauth.enabled')) {
                    authType = 'basicauth';
                } else if(config.get('opendistro_security.jwt.enabled')) {
                    authType = 'jwt';
                }

                // Dynamically update the auth.type to make it available to the frontend
                if (authType) {
                    config.set('opendistro_security.auth.type', authType);
                }
            }

            // Set up the storage cookie
            let storageCookieConf = {
                path: '/',
                ttl: null, // Cookie deleted when the browser is closed
                password: config.get('opendistro_security.cookie.password'),
                encoding: 'iron',
                isSecure: config.get('opendistro_security.cookie.secure'),
                isSameSite: config.get('opendistro_security.cookie.isSameSite')
            };

            if (config.get('opendistro_security.cookie.domain')) {
                storageCookieConf["domain"] = config.get('opendistro_security.cookie.domain');
            }

            server.state('security_storage', storageCookieConf);

            if (authType && authType !== '' && ['basicauth', 'jwt', 'openid', 'saml', 'proxycache'].indexOf(authType) > -1) {
                try {
                    await server.register({
                        plugin: require('hapi-auth-cookie')
                    });
                    this.status.yellow('Initialising Security authentication plugin.');

                    if (config.get("opendistro_security.cookie.password") == 'security_cookie_default_password') {
                        this.status.yellow("Default cookie password detected, please set a password in kibana.yml by setting 'opendistro_security.cookie.password' (min. 32 characters).");
                    }

                    if (!config.get("opendistro_security.cookie.secure")) {
                        this.status.yellow("'opendistro_security.cookie.secure' is set to false, cookies are transmitted over unsecure HTTP connection. Consider using HTTPS and set this key to 'true'");
                    }


                    if (authType == 'openid') {
                        let OpenId = require('./lib/auth/types/openid/OpenId');
                        authClass = new OpenId(pluginRoot, server, this, APP_ROOT, API_ROOT);
                        server.log("openid");
                    } else if (authType == 'basicauth') {
                        let BasicAuth = require('./lib/auth/types/basicauth/BasicAuth');
                        authClass = new BasicAuth(pluginRoot, server, this, APP_ROOT, API_ROOT);
                    } else if (authType == 'jwt') {
                        let Jwt = require('./lib/auth/types/jwt/Jwt');
                        authClass = new Jwt(pluginRoot, server, this, APP_ROOT, API_ROOT);
                        this.status.yellow("Security copy JWT params registered.");
                    } else if (authType == 'saml') {
                        let Saml = require('./lib/auth/types/saml/Saml');
                        authClass = new Saml(pluginRoot, server, this, APP_ROOT, API_ROOT);
                    } else if (authType == 'proxycache') {
                        let ProxyCache = require('./lib/auth/types/proxycache/ProxyCache');
                        authClass = new ProxyCache(pluginRoot, server, this, APP_ROOT, API_ROOT);
                    }

                    if (authClass) {
                        try {
                            // At the moment this is mainly to catch an error where the openid connect_url is wrong
                            await authClass.init();
                        } catch (error) {
                            this.status.red('An error occurred during initialisation, please check the logs.');
                            return;
                        }

                        this.status.yellow('Security session management enabled.');
                    }
                } catch (error) {
                    server.log(['error', 'security'], `An error occurred registering server plugins: ${error}`);
                    this.status.red('An error occurred during initialisation, please check the logs.');
                    return;
                }


            } else {
                // @todo await/async
                // Register the storage plugin for the other auth types
                server.register({
                    plugin: pluginRoot('lib/session/sessionPlugin'),
                    options: {
                        authType: null,
                    }
                })
            }

            if (authType != 'jwt') {
                this.status.yellow("Security copy JWT params disabled");
            }

            if (config.get('opendistro_security.xff.enabled')) {
                require('./lib/xff/xff')(pluginRoot, server, this);
                this.status.yellow("Opendistro Security XFF enabled.");
            }
            if (config.get('opendistro_security.multitenancy.enabled')) {

                // sanity check - header whitelisted?
                var headersWhitelist = config.get('elasticsearch.requestHeadersWhitelist');
                if (headersWhitelist.indexOf('securitytenant') == -1) {
                    this.status.red('No tenant header found in whitelist. Please add securitytenant to elasticsearch.requestHeadersWhitelist in kibana.yml');
                    return;
                }

                require('./lib/multitenancy/routes')(pluginRoot, server, this, APP_ROOT, API_ROOT);
                require('./lib/multitenancy/headers')(pluginRoot, server, this, APP_ROOT, API_ROOT, authClass);

                let preferenceCookieConf = {
                    ttl: 2217100485000,
                    path: '/',
                    isSecure: false,
                    isHttpOnly: false,
                    clearInvalid: true, // remove invalid cookies
                    strictHeader: true, // don't allow violations of RFC 6265
                    encoding: 'iron',
                    password: config.get("opendistro_security.cookie.password"),
                    isSameSite: config.get('opendistro_security.cookie.isSameSite')
                };

                if (config.get('opendistro_security.cookie.domain')) {
                    preferenceCookieConf["domain"] = config.get('opendistro_security.cookie.domain');
                }

                server.state('security_preferences', preferenceCookieConf);


                this.status.yellow("Security multitenancy registered.");
            } else {
                this.status.yellow("Security multitenancy disabled");
            }

            // Assign auth header after MT
            if (authClass) {
                authClass.registerAssignAuthHeader();
            }

            if (config.get('opendistro_security.configuration.enabled')) {
                require('./lib/configuration/routes/routes')(pluginRoot, server, APP_ROOT, API_ROOT);
                this.status.yellow("Routes for Security configuration GUI registered.");
            } else {
                this.status.yellow("Security configuration GUI disabled");
            }

            // create index template for tenant indices
            if(config.get('opendistro_security.multitenancy.enabled')) {
                const { setupIndexTemplate, waitForElasticsearchGreen } = indexTemplate(this, server);
                //const {migrateTenants} = tenantMigrator(this, server);

                waitForElasticsearchGreen().then( () => {
                    this.status.yellow('Setting up index template.');
                    setupIndexTemplate();

                    migrateTenants(server)
                        .then(  () => {
                            this.status.green('Open Distro Security plugin version '+ opendistro_security_version + ' initialised.');
                        })
                        .catch((error) => {
                            this.status.yellow('Tenant indices migration failed');
                        });

                });

            } else {
                this.status.green('Open Distro Security plugin version '+ opendistro_security_version + ' initialised.');
            }

            // Using an admin certificate may lead to unintended consequences
            if ((typeof config.get('elasticsearch.ssl.certificate') !== 'undefined' && typeof config.get('elasticsearch.ssl.certificate') !== false) && config.get('opendistro_security.allow_client_certificates') !== true) {
                this.status.red("'elasticsearch.ssl.certificate' can not be used without setting 'opendistro_security.allow_client_certificates' to 'true' in kibana.yml. Please refer to the documentation for more information about the implications of doing so.");
            }
        }
    });
};
