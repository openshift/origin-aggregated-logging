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

import chrome from 'ui/chrome';
import { uiModules } from 'ui/modules';
import { toastNotifications } from 'ui/notify';
import './readonly.less';

// Needed to access the dashboardProvider
import 'plugins/kibana/dashboard/dashboard_config';

/**
 * Holds resolved information
 * @type {Object|null}
 */
let resolvedReadOnly = null;

/**
 * We only want to show the read only message once per page load
 * @type {boolean}
 */
let readOnlyMessageAlreadyShown = false;

// As of today, the dashboardConfigProvider doesn't provide a setter
// with which we can change the state after Angular's config phase.
// Hence, we extend it with our own method.
uiModules.get('kibana').config((dashboardConfigProvider) => {

    let providerGetter = dashboardConfigProvider.$get();

    // This method will be added to the providers $get function (standard Angular provider)
    providerGetter.setHideWriteControls = function(){
        this.turnHideWriteControlsOn()
    }.bind(dashboardConfigProvider);

    // Makes the setter available in the original provider
    dashboardConfigProvider.$get = function() {
        return providerGetter;
    };
});

/**
 * Holds the original state of the navigation links "hidden" property
 * @type {null|Object}
 */
let originalNavItemsVisibility = null;

/**
 * If at least one readonly role is configured, we start by hiding
 * the navigation links until we have resolved the the readonly
 * status of the current user
 */
function hideNavItems() {
    originalNavItemsVisibility = {};
    chrome.getNavLinks().forEach((navLink) => {
        if (navLink.id !== 'kibana:dashboard') {

            originalNavItemsVisibility[navLink.id] = navLink.hidden;
            navLink.hidden = true;

            // This is a bit of a hack to make sure that we detect
            // changes that happen between reading the original
            // state and resolving our info
            navLink._securityHidden = navLink.hidden;
            Object.defineProperty(navLink, 'hidden', {
                set(value) {
                    originalNavItemsVisibility[this.id] = value;
                    this._securityHidden = value;
                },
                get() {
                    return this._securityHidden;
                }
            });
        }
    });
}

/**
 * Hide navigation links that aren't needed in tenant read only mode
 */
function hideNavItemsForTenantReadOnly() {
    let hiddenNavLinkIds = [
        'kibana:management'
    ];

    chrome.getNavLinks().forEach((navLink) => {
        if (hiddenNavLinkIds.indexOf(navLink.id) > -1) {
            // A bit redundant if all items are hidden from the start
            navLink.hidden = true;
        } else if (originalNavItemsVisibility !== null) {
            navLink.hidden = originalNavItemsVisibility[navLink.id];
        }
    });
}

/**
 * Hide navigation links that aren't needed in the dashboard only mode.
 * @param {Boolean} multitenancyVisible - If true, we won't hide the
 */
function hideNavItemsForDashboardOnly(multitenancyVisible) {
    let visibleNavLinkIds = [
        'kibana:dashboard',
    ];

    if (multitenancyVisible) {
        visibleNavLinkIds.push('security-multitenancy');
    }

    chrome.getNavLinks().forEach((navLink) => {
        if (visibleNavLinkIds.indexOf(navLink.id) === -1) {
            // A bit redundant if all items are hidden from the start
            navLink.hidden = true;
        } else if (originalNavItemsVisibility !== null) {
            navLink.hidden = originalNavItemsVisibility[navLink.id];
        }
    });
}

/**
 * For the dasboard only role. Blocks and redirects sub routes (e.g. visualize) that belong to the Kibana app.
 * As of now, everything except for /dashboards or /dashboard/:id is redirected.
 * @param $rootScope
 * @param $location
 * @param allowedPaths Paths allowed in addition to the dashboard paths
 */
function handleRoutingForDashboardOnly($rootScope, $location) {

    $rootScope.$on('$routeChangeSuccess', function(event, next, current) {
        let currentPath = chrome.removeBasePath(location.pathname);

        if (currentPath === '/app/kibana' && next.$$route) {
            const intendedPath = next.$$route.originalPath || '';
            if (intendedPath.indexOf('/dashboard') !== 0) {
                $location.path('/dashboards');
            }

            return false;
        }
    });
}

/**
 * This is to avoid the redirect that happens when route.requireDefaultIndex = true
 * and we for some reason don't have a default index. We do set the requireDefaultIndex
 * to false as soon as we have resolved a route, but the Management redirect happens
 * before we are able to stop it.
 *
 * Also, we need to show a message that the user can't edit or save anything while in read only mode.
 * Some controls can be hidden with CSS, but not all of them (reliably).
 *
 * @param $rootScope
 * @param $location
 */
function handleRoutingForTenantReadOnly($rootScope, $location) {

    $rootScope.$on('$routeChangeSuccess', function (event, next, current) {
        if (next.$$route.originalPath.indexOf('/management') == 0 && next.locals.security_resolvedInfo.isReadOnly) {
            // @todo For tenantReadOnly we may need to redirect to discover, visualize. Check the path of current?
            $location.path('/dashboards');
        }

        // We can't reliably hide all the edit- and write controls, so instead we show a read only message.
        if (readOnlyMessageAlreadyShown === false) {
            let currentPath = chrome.removeBasePath(location.pathname);
            // Only show the message in the kibana app(?)
            if (currentPath.indexOf('/app/kibana') !== 0) {
                return;
            }
            readOnlyMessageAlreadyShown = true;

            toastNotifications.addDanger({
                title: 'Read Only',
                text: 'Since this tenant is read only, you will not be able to save any changes you make.'
            });
        }
    });

}

/**
 * Add a CSS helper class for the read only mode
 * @param {boolean} isReadOnlyTenant - Different classes for the different cases
 */
function addReadOnlyCSSHelper(isReadOnlyTenant = false) {
    if (isReadOnlyTenant) {
        document.body.classList.add('security-isReadOnlyTenant');
    } else {
        document.body.classList.add('security-isReadOnly');
    }

}

/**
 * Response for when we have a read only tenant
 * @param $rootScope
 * @param $location
 * @param dashboardConfig
 * @returns {Object}
 */
function resolveWithTenantReadOnly($rootScope, $location, dashboardConfig, authInfo) {
    // We can't use the built in function here since it hides too many controls
    // Instead, this is handled in the CSS
    //dashboardConfig.setHideWriteControls();
    hideNavItemsForTenantReadOnly();
    handleRoutingForTenantReadOnly($rootScope, $location);
    addReadOnlyCSSHelper(true);

    resolvedReadOnly = {
        tenantIsReadOnly: true,
        isReadOnly: true,
        userRequestedTenant: authInfo.user_requested_tenant
    };

    return resolvedReadOnly;
}

/**
 * Response for when we have a dashboard only role
 * @param $q
 * @param $rootScope
 * @param $location
 * @param route
 * @param dashboardConfig
 * @param authInfo
 * @returns {*}
 */
function resolveWithDashboardRole($q, $rootScope, $location, route, dashboardConfig, authInfo) {

    // If we have more than one tenant, we will leave the tenants app visible
    const globalTenantEnabled = chrome.getInjected('multitenancy.tenants.enable_global');
    let numberOfTenants = Object.keys(authInfo.tenants).length;
    if (globalTenantEnabled) {
        numberOfTenants++;
    }

    let allowedPaths = ['/app/kibana'];

    if (numberOfTenants > 1) {
        allowedPaths.push('/app/security-multitenancy')
    }

    // If we're outside of the kibana app, we can redirect away from the route
    // to avoid flickering when the intended path/view is loaded and rendered.
    let appPath = chrome.removeBasePath(location.pathname);
    if (allowedPaths.indexOf(appPath) === -1) {
        // This should be safe as long as we have a full page reload between apps.
        window.location.href = chrome.getBasePath() + '/app/kibana#/dashboards';
        // Stop the route from rendering, otherwise the originally intended page is loaded before the redirect happens
        return $q.reject();
    }

    dashboardConfig.setHideWriteControls();
    handleRoutingForDashboardOnly($rootScope, $location);
    hideNavItemsForDashboardOnly((numberOfTenants > 1));
    addReadOnlyCSSHelper();

    resolvedReadOnly = {
        hasDashboardRole: true,
        isReadOnly: true,
        userRequestedTenant: authInfo.user_requested_tenant
    };
    return resolvedReadOnly;

}

function resolveRegular(authInfo) {

    resolvedReadOnly = {
        hasDashboardRole: false,
        tenantIsReadOnly: false,
        isReadOnly: false,
        userRequestedTenant: authInfo.user_requested_tenant
    };

    // If we hid all navigation links before resolving we need to
    // change them back to their original state
    if (originalNavItemsVisibility !== null) {
        chrome.getNavLinks().forEach((navLink) => {
            navLink.hidden = originalNavItemsVisibility[navLink.id];
        });
    }

    return resolvedReadOnly;
}

/**
 * Logic for deciding whether a user is
 * - in a read only tenant
 * - has a dashboard only role
 *
 * A dashboard only role trumps write access on a tenant.
 *
 * @param $q
 * @param $rootScope
 * @param $http
 * @param $location
 * @param route
 * @param dashboardConfig
 * @returns {*}
 */
function readOnlyResolver($q, $rootScope, $http, $location, route, dashboardConfig) {

    // If we've already fetched what we need, just return/resolve it to save us the AJAX calls
    if (resolvedReadOnly !== null) {
        if (resolvedReadOnly.isReadOnly) {
            // Tell Kibana that we don't want to redirect to the management app
            // even if we don't have a default index.
            route.requireDefaultIndex = false;
        }

        return $q.when(resolvedReadOnly);
    }

    const ROOT = chrome.getBasePath();
    const APP_ROOT = `${ROOT}`;
    const API_ROOT = `${APP_ROOT}/api/v1`;
    const GLOBAL_TENANT_VALUE = '';
    const PRIVATE_TENANT_VALUE = '__user__';

    let readOnlyConfig = chrome.getInjected('readonly_mode');

    // If we deactivate the entire feature, we should just return quickly here.
    // We could also skip the resolver entirely, but then we need to make sure that we're not relying
    // on the resolver being injected in any controllers (e.g. in multitenancy.js)
    return $http.get(`${API_ROOT}/auth/authinfo`)
        .then((response) => {

            const configReadOnlyRoles = readOnlyConfig.roles;
            let authInfo = response.data;

            let userReadOnlyRoles = authInfo.roles.filter((role) => {
                return (configReadOnlyRoles.indexOf(role) > -1);
            });

            let isReadOnlyByRole = (userReadOnlyRoles.length > 0);
            if (isReadOnlyByRole) {
                // A dashboardOnly role trumps the tenant access rights,
                // so we can return early here.
                return resolveWithDashboardRole($q, $rootScope, $location, route, dashboardConfig, authInfo);
            }

            // If the user is on the global tenant, we need to get the
            // access right via the multitenancy endpoint
            if (authInfo.user_requested_tenant == GLOBAL_TENANT_VALUE) {

                return $http.get(`${API_ROOT}/multitenancy/info`)
                    .then((response) => {
                        let mtinfo = response.data;

                        if (mtinfo.kibana_index_readonly) {
                            return resolveWithTenantReadOnly($rootScope, $location, dashboardConfig, authInfo);
                        } else {
                            return resolveRegular(authInfo);
                        }
                    });

            } else {
                // Not on global, so we already have the access rights.
                if (
                    (authInfo.user_requested_tenant == PRIVATE_TENANT_VALUE && authInfo.tenants[authInfo.user_name] === false)
                    ||
                    (authInfo.tenants[authInfo.user_requested_tenant] === false)
                ) {
                    return resolveWithTenantReadOnly($rootScope, $location, dashboardConfig, authInfo);
                }

            }

            return resolveRegular(authInfo);
        });
}

/**
 * Adds a resolve to all routes which checks for a dashboard only role,
 * or whether the current tenant is read only.
 *
 * @param $rootScope
 * @param $http
 * @param $window
 * @param $timeout
 * @param $q
 * @param $location
 * @param $injector
 * @param dashboardConfig
 */
export function enableReadOnly($rootScope, $http, $window, $timeout, $q, $location, $injector, dashboardConfig) {
    const readOnlyConfig = chrome.getInjected('readonly_mode');
    const path = chrome.removeBasePath($window.location.pathname);

    // don't run on login or logout, we don't have any user on these pages
    if(path === '/login' || path === '/logout' || path === '/customerror') {
        return;
    }


    if (!$injector.has('$route')) {
        return;
    }

    let $route = $injector.get('$route');
    if ($route.routes) {
        // Hide the navigation items by default if we have at leason one readonly role
        if (readOnlyConfig.roles && readOnlyConfig.roles.length) {
            hideNavItems();
        }

        // Add the resolver to each of the routes defined in the current app.
        // We do it in all apps so that we know when to hide the navigation links.
        for (let routeUrl in $route.routes) {
            let route = $route.routes[routeUrl];
            // Some of the routes are just redirected
            if (! route.redirectTo) {

                if (typeof route.resolve === 'undefined') {
                    route.resolve = {};
                }

                route.resolve['security_resolvedInfo'] = function() {
                    return readOnlyResolver($q, $rootScope, $http, $location, route, dashboardConfig);
                }
            }
        }
    }

    // Set the path on the body element to allow us to hide
    // some of the edit- and write controls with CSS.
    $rootScope.$on('$routeChangeSuccess', function(event, next, current) {
        if (next && next.$$route && next.$$route.originalPath) {
            document.body.setAttribute('security_path', next.$$route.originalPath.replace(':', '').split('/').join('_'));

        }
    });

}

uiModules.get('security').run(enableReadOnly);
