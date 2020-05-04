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
import {messageTypes} from "./errormessage_types";


export default function PageController() {

    const ROOT = chrome.getBasePath();
    const BRANDIMAGE = chrome.getInjected("basicauth.login.brandimage");

    this.buttonHref = ROOT + '/app/kibana';

    // Button styles, same as the basic auth login styles
    this.buttonstyle = chrome.getInjected("basicauth.login.buttonstyle");

    // if session was not terminated by logout, clear any remaining
    // stored paths etc. from previous users, to avoid issues
    // like a non-working default index pattern
    localStorage.clear();
    sessionStorage.clear();

    let type = null;

    // Strip the first ? from the query parameters, if we have any
    let queryString = location.search.trim().replace(/^(\?)/, '');

    if (queryString) {
        queryString.split('&')
            .map((parameter) => {
                let parameterParts = parameter.split('=');
                if (parameterParts[0].toLowerCase() === 'type') {
                    type = parameterParts[1];
                }
            })
    };

    if (! type || ! messageTypes[type]) {
        this.title = messageTypes['default'].title;
        this.subtitle = messageTypes['default'].subtitle;
    } else {
        this.title = messageTypes[type].title;
        this.subtitle = messageTypes[type].subtitle;
    }

    // Custom styling
    this.showbrandimage = chrome.getInjected("basicauth.login.showbrandimage");
    this.brandimage = chrome.getInjected("basicauth.login.brandimage");



    if (BRANDIMAGE.startsWith("/plugins")) {
        this.brandimage = ROOT + BRANDIMAGE;
    } else {
        this.brandimage = BRANDIMAGE;
    }

};
