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

import { parse } from 'url';

export function getNextUrl(currentUrl, basePath = '') {

    const {query, hash} = parse(currentUrl, true, true);

    // no nexturl in query, redirect to basepath
    if (!query.nextUrl) {
        return `${basePath}/`;
    }

    // check next url is valid and does not redirect to a malicious site.

    // check forgery of protocol, hostname, port, pathname
    const { protocol, hostname, port, pathname } = parse(query.nextUrl, false, true);

    if (protocol !== null || hostname !== null || port !== null) {
        return `${basePath}/`;
    }

    // check we only redirect to our own base path
    if (!String(pathname).startsWith(basePath)) {
        return `${basePath}/`;
    }

    // next url valid, append hash if any
    return query.nextUrl + (hash || '');

}
