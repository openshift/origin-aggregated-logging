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
import React from 'react';
import { render } from 'react-dom';
import * as Rx from 'rxjs';
import { first, tap } from 'rxjs/operators';
import { FatalErrorsScreen } from './fatal_errors_screen';
import { getErrorInfo } from './get_error_info';
var FatalErrorsService = /** @class */ (function () {
    function FatalErrorsService(params) {
        var _this = this;
        this.params = params;
        this.errorInfo$ = new Rx.ReplaySubject();
        this.add = function (error, source) {
            var errorInfo = getErrorInfo(error, source);
            _this.errorInfo$.next(errorInfo);
            if (error instanceof Error) {
                // make stack traces clickable by putting whole error in the console
                // tslint:disable-next-line no-console
                console.error(error);
            }
            throw error;
        };
        this.errorInfo$
            .pipe(first(), tap(function () { return _this.onFirstError(); }))
            .subscribe({
            error: function (error) {
                // tslint:disable-next-line no-console
                console.error('Uncaught error in fatal error screen internals', error);
            },
        });
    }
    FatalErrorsService.prototype.start = function (_a) {
        var _this = this;
        var i18n = _a.i18n;
        this.i18n = i18n;
        return {
            add: this.add,
            get$: function () {
                return _this.errorInfo$.asObservable();
            },
        };
    };
    FatalErrorsService.prototype.onFirstError = function () {
        // stop the core systems so that things like the legacy platform are stopped
        // and angular/react components are unmounted;
        this.params.stopCoreSystem();
        // delete all content in the rootDomElement
        this.params.rootDomElement.textContent = '';
        // create and mount a container for the <FatalErrorScreen>
        var container = document.createElement('div');
        this.params.rootDomElement.appendChild(container);
        // If error occurred before I18nService has been started we don't have any
        // i18n context to provide.
        var I18nContext = this.i18n ? this.i18n.Context : React.Fragment;
        render(React.createElement(I18nContext, null,
            React.createElement(FatalErrorsScreen, { buildNumber: this.params.injectedMetadata.getKibanaBuildNumber(), kibanaVersion: this.params.injectedMetadata.getKibanaVersion(), "errorInfo$": this.errorInfo$ })), container);
    };
    return FatalErrorsService;
}());
export { FatalErrorsService };
