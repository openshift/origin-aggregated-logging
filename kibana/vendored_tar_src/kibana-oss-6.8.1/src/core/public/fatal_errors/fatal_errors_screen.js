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
import { EuiButton, EuiButtonEmpty, EuiCallOut, EuiCodeBlock, EuiEmptyPrompt, EuiPage, EuiPageBody, EuiPageContent, } from '@elastic/eui';
import React from 'react';
import * as Rx from 'rxjs';
import { tap } from 'rxjs/operators';
import { FormattedMessage } from '@kbn/i18n/react';
var FatalErrorsScreen = /** @class */ (function (_super) {
    tslib_1.__extends(FatalErrorsScreen, _super);
    function FatalErrorsScreen() {
        var _this = _super !== null && _super.apply(this, arguments) || this;
        _this.state = {
            errors: [],
        };
        _this.onClickGoBack = function (e) {
            e.preventDefault();
            window.history.back();
        };
        _this.onClickClearSession = function (e) {
            e.preventDefault();
            localStorage.clear();
            sessionStorage.clear();
            window.location.hash = '';
            window.location.reload();
        };
        return _this;
    }
    FatalErrorsScreen.prototype.componentDidMount = function () {
        var _this = this;
        this.subscription = Rx.merge(
        // reload the page if hash-based navigation is attempted
        Rx.fromEvent(window, 'hashchange').pipe(tap(function () {
            window.location.reload();
        })), 
        // consume error notifications and set them to the component state
        this.props.errorInfo$.pipe(tap(function (error) {
            _this.setState(function (state) { return (tslib_1.__assign({}, state, { errors: tslib_1.__spread(state.errors, [error]) })); });
        }))).subscribe({
            error: function (error) {
                // tslint:disable-next-line no-console
                console.error('Uncaught error in fatal error screen internals', error);
            },
        });
    };
    FatalErrorsScreen.prototype.componentWillUnmount = function () {
        if (this.subscription) {
            this.subscription.unsubscribe();
            this.subscription = undefined;
        }
    };
    FatalErrorsScreen.prototype.render = function () {
        var _this = this;
        return (React.createElement(EuiPage, { style: { minHeight: '100vh' } },
            React.createElement(EuiPageBody, null,
                React.createElement(EuiPageContent, { verticalPosition: "center", horizontalPosition: "center" },
                    React.createElement(EuiEmptyPrompt, { iconType: "alert", iconColor: "danger", title: React.createElement("h2", null,
                            React.createElement(FormattedMessage, { id: "core.fatalErrors.somethingWentWrongTitle", defaultMessage: "Something went wrong" })), body: React.createElement("p", null,
                            React.createElement(FormattedMessage, { id: "core.fatalErrors.tryRefreshingPageDescription", defaultMessage: "Try refreshing the page. If that doesn't work, go back to the previous page or\n                    clear your session data." })), actions: [
                            React.createElement(EuiButton, { color: "primary", fill: true, onClick: this.onClickClearSession, "data-test-subj": "clearSession" },
                                React.createElement(FormattedMessage, { id: "core.fatalErrors.clearYourSessionButtonLabel", defaultMessage: "Clear your session" })),
                            React.createElement(EuiButtonEmpty, { onClick: this.onClickGoBack, "data-test-subj": "goBack" },
                                React.createElement(FormattedMessage, { id: "core.fatalErrors.goBackButtonLabel", defaultMessage: "Go back" })),
                        ] }),
                    this.state.errors.map(function (error, i) { return (React.createElement(EuiCallOut, { key: i, title: error.message, color: "danger", iconType: "alert" },
                        React.createElement(EuiCodeBlock, { language: "bash", className: "eui-textBreakAll" }, "Version: " + _this.props.kibanaVersion +
                            '\n' +
                            ("Build: " + _this.props.buildNumber) +
                            '\n' +
                            (error.stack ? error.stack : '')))); })))));
    };
    return FatalErrorsScreen;
}(React.Component));
export { FatalErrorsScreen };
