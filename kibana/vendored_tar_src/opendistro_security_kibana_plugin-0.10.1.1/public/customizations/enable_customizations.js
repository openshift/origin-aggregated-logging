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


const APP_ROOT = `${chrome.getBasePath()}`;
let kibanaBaseUrl;

/**
 * Handles an infinite loop in the monitoring app
 * when the user lacks the correct permissions.
 * @param $injector
 */
function handleMonitoringLoop($injector) {

    const currentApp = chrome.getApp();

    if (currentApp.id !== 'monitoring') {
        return;
    }

    if (!$injector.has('$route')) {
        return;
    }

    const $window = $injector.get('$window');
    const $route = $injector.get('$route');
    if ($route.routes) {
        for (let routeUrl in $route.routes) {
            let route = $route.routes[routeUrl]
            // Override the controller and the resolver for the access denied route
            if (routeUrl.indexOf('/access-denied') > -1 && route.resolve && route.resolve.initialCheck) {
                route.controller = function() {
                    // The template's "Back to Kibana" button click handler
                    this.goToKibana = () => {
                        $window.location.href = APP_ROOT + kibanaBaseUrl;
                    };
                };
                // Remove the original resolver
                route.resolve = {};
            }
        }
    }
}

export function enableCustomizations($injector) {
    try {
        kibanaBaseUrl = $injector.get('kbnBaseUrl');

        handleMonitoringLoop($injector);
    } catch (error) {
        // Ignore
    }
}

uiModules.get('security').run(enableCustomizations);
