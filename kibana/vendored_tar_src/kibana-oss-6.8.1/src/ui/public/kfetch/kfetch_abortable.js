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
import * as tslib_1 from "tslib";
import { kfetch } from './kfetch';
function createAbortable() {
    var abortController = new AbortController();
    var signal = abortController.signal, abort = abortController.abort;
    return {
        signal: signal,
        abort: abort.bind(abortController),
    };
}
export function kfetchAbortable(fetchOptions, kibanaOptions) {
    var _a = createAbortable(), signal = _a.signal, abort = _a.abort;
    var fetching = kfetch(tslib_1.__assign({}, fetchOptions, { signal: signal }), kibanaOptions);
    return {
        fetching: fetching,
        abort: abort,
    };
}
