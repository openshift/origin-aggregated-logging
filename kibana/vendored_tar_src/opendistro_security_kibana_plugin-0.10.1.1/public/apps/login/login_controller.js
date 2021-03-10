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
import {parse} from 'url';
import _ from 'lodash';
import {getNextUrl} from './get_next_url';

require ('../configuration/systemstate/systemstate');

export default function LoginController(kbnUrl, $scope, $http, $window, systemstate) {

    const ROOT = chrome.getBasePath();
    const APP_ROOT = `${ROOT}`;
    const API_ROOT = `${APP_ROOT}/api/v1`;
    const BRANDIMAGE = chrome.getInjected("basicauth.login.brandimage");

    // if session was not terminated by logout, clear any remaining
    // stored paths etc. from previous users, to avoid issues
    // like a non-working default index pattern
    localStorage.clear();
    sessionStorage.clear();

    // Custom styling
    this.errorMessage = false;
    this.logintitle = chrome.getInjected("basicauth.login.title");
    this.loginsubtitle = chrome.getInjected("basicauth.login.subtitle");
    this.showbrandimage = chrome.getInjected("basicauth.login.showbrandimage");
    this.brandimage = chrome.getInjected("basicauth.login.brandimage");
    this.buttonstyle = chrome.getInjected("basicauth.login.buttonstyle");

    const alternativeLoginConfig = chrome.getInjected("basicauth.alternative_login");

    // Build an object from the query parameters
    // Strip the first ? from the query parameters, if we have any
    let queryString = location.search.trim().replace(/^(\?)/, '');
    let queryObject = {};
    if (queryString) {
        queryString.split('&')
            .map((parameter) => {
                let parameterParts = parameter.split('=');
                if (parameterParts[1]) {
                    queryObject[encodeURIComponent(parameterParts[0])] = parameterParts[1]
                }
            })
    }

    // Prepare alternative login for the view
    this.alternativeLogin = null;

    if (alternativeLoginConfig && alternativeLoginConfig.show_for_parameter) {

        let alternativeLoginURL = queryObject[alternativeLoginConfig.show_for_parameter];
        let validRedirect = false;

        try {
            alternativeLoginConfig.valid_redirects.forEach((redirect) => {
                if (new RegExp(redirect).test(alternativeLoginURL)) {
                    validRedirect = true;
                }
            });
        } catch (error) {
            console.warn(error);
        }

        if (validRedirect) {
            this.alternativeLogin = {
                url: queryObject[alternativeLoginConfig.show_for_parameter],
                styles: alternativeLoginConfig.buttonstyle,
                buttonLabel: alternativeLoginConfig.button_text,
            };
        }
    }

    if (BRANDIMAGE.startsWith("/plugins")) {
        this.brandimage = ROOT + BRANDIMAGE;
    } else {
        this.brandimage = BRANDIMAGE;
    }

    // honor last request URL
    let nextUrl = getNextUrl($window.location.href, ROOT);

    this.submit =  () => {

        try {
            $http.post(`${API_ROOT}/auth/login`, this.credentials)
                .then(
                (response) => {
                    // cache the current user information, we need it at several places
                    sessionStorage.setItem("security_user", JSON.stringify(response.data));
                    // load and cache rest api info
                    // perform in the callback due to Chrome cancelling the
                    // promises if we navigate away from the page, even if async/await
                    systemstate.loadRestInfo().then((response) => {
                        var user = JSON.parse(sessionStorage.getItem("security_user"));
                        $window.location.href = `${nextUrl}`;
                    });
                },
                (error) => {
                    if (error.status && error.status === 401) {
                        this.errorMessage = 'Invalid username or password, please try again';
                    } else if (error.status && error.status === 404) {
                        // This happens either when the user doesn't have any valid tenants or roles
                        this.errorMessage = error.data.message;
                    } else {
                        this.errorMessage = 'An error occurred while checking your credentials, make sure you have an Elasticsearch cluster secured by Security running.';
                    }
                }
            );
        } catch(error) {
            this.errorMessage = 'An internal error has occured.';
        }


    };

};
