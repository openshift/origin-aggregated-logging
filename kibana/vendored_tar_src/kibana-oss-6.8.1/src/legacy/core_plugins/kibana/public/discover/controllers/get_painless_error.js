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
import { i18n } from '@kbn/i18n';
import { get } from 'lodash';
export function getPainlessError(error) {
    var rootCause = get(error, 'resp.error.root_cause');
    if (!rootCause) {
        return;
    }
    var _a = tslib_1.__read(rootCause, 1), _b = _a[0], lang = _b.lang, script = _b.script;
    if (lang !== 'painless') {
        return;
    }
    return {
        lang: lang,
        script: script,
        message: i18n.translate('kbn.discover.painlessError.painlessScriptedFieldErrorMessage', {
            defaultMessage: "Error with Painless scripted field '{script}'.",
            values: { script: script },
        }),
        error: error.message,
    };
}
