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

/**
 *
 * @param nextUrl - Only the query parameter value, instead of the complete url. We don't always have the full url.
 * @param basePath
 * @returns {*}
 */
export function parseNextUrl(nextUrl, basePath) {

    // check forgery of protocol, hostname, port, pathname
    const { protocol, hostname, port, pathname, hash } = parse(nextUrl, true, true);
    // If we have a relative protocol, hostname is reported as an empty string, so we need to make sure it is null
    if (protocol !== null || hostname !== null || port !== null) {
        return `${basePath}/`;
    }

    // We always need the base path
    if (!String(pathname).startsWith(basePath)) {
        if (nextUrl && nextUrl != null && nextUrl.startsWith("/")) {
            nextUrl = nextUrl.substring(1);
        }
        return `${basePath}/${nextUrl}`;
    }

    // All valid
    return nextUrl;

}
