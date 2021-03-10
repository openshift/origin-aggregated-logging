/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
import { parse } from 'url';
import { extractAppPathAndId } from './extract_app_path_and_id';
import { KibanaParsedUrl } from './kibana_parsed_url';
/**
 *
 * @param absoluteUrl - an absolute url, e.g. https://localhost:5601/gra/app/kibana#/visualize/edit/viz_id?hi=bye
 * @param basePath - An optional base path for kibana. If supplied, should start with a "/".
 * e.g. in https://localhost:5601/gra/app/kibana#/visualize/edit/viz_id the basePath is
 * "/gra".
 * @return {KibanaParsedUrl}
 */
export function absoluteToParsedUrl(absoluteUrl, basePath) {
    if (basePath === void 0) { basePath = ''; }
    var _a = extractAppPathAndId(absoluteUrl, basePath), appPath = _a.appPath, appId = _a.appId;
    var _b = parse(absoluteUrl), hostname = _b.hostname, port = _b.port, protocol = _b.protocol;
    return new KibanaParsedUrl({
        basePath: basePath,
        appId: appId,
        appPath: appPath,
        hostname: hostname,
        port: port,
        protocol: protocol,
    });
}
