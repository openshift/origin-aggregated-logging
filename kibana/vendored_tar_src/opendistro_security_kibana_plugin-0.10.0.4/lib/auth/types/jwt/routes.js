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

module.exports = function (pluginRoot, server, kbnServer, APP_ROOT, API_ROOT) {

    const customErrorApp = server.getHiddenUiAppById('security-customerror');

    /**
     * After a logout we are redirected to a login page
     */
    server.route({
        method: 'GET',
        path:  `${APP_ROOT}/login`,
        handler(request, h) {
            return h.renderAppWithDefaultConfig(customErrorApp);
        },
        options: {
            auth: false
        }
    });

    /**
     * The error page.
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

    server.route({
        method: 'POST',
        path: `${API_ROOT}/auth/logout`,
        handler: (request, h) => {
            request.auth.securitySessionStorage.clear();
            return {};
        },
        options: {
            auth: false
        }
    });

}; //end module
