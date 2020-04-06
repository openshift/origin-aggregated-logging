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

import Boom from 'boom';
import {assign} from 'lodash';
import User from '../auth/user';
const querystring = require('querystring')

export default function (pluginRoot, server, APP_ROOT, API_ROOT) {
    const config = server.config();
    const basePath = config.get('server.basePath');
    const unauthenticatedRoutes = config.get('opendistro_security.basicauth.unauthenticated_routes');
    // START add default unauthenticated routes
    // END add default unauthenticated routes
    const cookieConfig = {
      password: config.get('opendistro_security.cookie.password'),
      cookie: config.get('opendistro_security.cookie.name'),
      isSecure: config.get('opendistro_security.cookie.secure'),
      validateFunc: pluginRoot('lib/session/validate')(server),
      ttl: config.get('opendistro_security.cookie.ttl')
    };

    server.auth.strategy('security_access_control_cookie', 'cookie', false, cookieConfig);

    server.auth.scheme('security_access_control_scheme', (server, options) => ({
        authenticate: (request, reply) => {
            if (request.headers.authorization) {
                var tmp = request.headers.authorization.split(' ');
                var creds = new Buffer(tmp[1], 'base64').toString().split(':');
                var username = creds[0];
                var password = creds[1];
                var credentials = server.plugins.opendistro_security.getSecurityBackend().getUser(username, password);
                reply.continue({credentials});
                return;
            }
            // let configured routes that are not under our control pass,
            // for example /api/status to check Kibana status without a logged in user
            if (unauthenticatedRoutes.includes(request.path)) {
                var credentials = server.plugins.opendistro_security.getSecurityBackend().getServerUser();
                reply.continue({credentials});
                return;
            };

            server.auth.test('security_access_control_cookie', request, (error, credentials) => {
                if (error) {
                    if (request.url.path.indexOf(API_ROOT) === 0 || request.method !== 'get') {
                        return reply(Boom.forbidden(error));
                    } else {
                        // If the session has expired, we may receive ajax requests that can't handle a 302 redirect.
                        // In this case, we trigger a 401 and let the interceptor handle the redirect on the client side.
                        if (request.headers && request.headers.accept && request.headers.accept.split(',').indexOf('application/json') > -1) {
                            // The redirectTo property in the payload tells the interceptor to handle this error.
                            return reply({message: 'Session expired', redirectTo: 'login'}).code(401);
                        }

                        const nextUrl = encodeURIComponent(request.url.path);

                        return reply.redirect(`${basePath}${APP_ROOT}/login?nextUrl=${nextUrl}`);
                    }
                }
                reply.continue({credentials});
            });
        }
    }));

    server.auth.strategy('security_access_control', 'security_access_control_scheme', true);

    server.ext('onPostAuth', function (request, next) {

        if (request.auth && request.auth.isAuthenticated) {
            const backend = server.plugins.opendistro_security.getSecurityBackend();
            return backend.getAuthHeaders(request.auth.credentials)
                .then((headers) => {
                    assign(request.headers, headers);
                    return next.continue();
                })
                .catch((error) => {
                    server.log(['security', 'error'], `An error occurred while computing auth headers, clearing session: ${error}`);
                    request.auth.session.clear();
                    // redirect to login somehow?
                    return next.continue();
                });
        }
        return next.continue();
    });

}
