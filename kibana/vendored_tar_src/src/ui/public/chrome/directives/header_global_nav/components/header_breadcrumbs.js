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
import React, { Component } from 'react';
import { 
// @ts-ignore
EuiHeaderBreadcrumbs, } from '@elastic/eui';
var HeaderBreadcrumbs = /** @class */ (function (_super) {
    tslib_1.__extends(HeaderBreadcrumbs, _super);
    function HeaderBreadcrumbs(props) {
        var _this = _super.call(this, props) || this;
        _this.state = { breadcrumbs: [] };
        return _this;
    }
    HeaderBreadcrumbs.prototype.componentDidMount = function () {
        this.subscribe();
    };
    HeaderBreadcrumbs.prototype.componentDidUpdate = function (prevProps) {
        if (prevProps.breadcrumbs$ === this.props.breadcrumbs$) {
            return;
        }
        this.unsubscribe();
        this.subscribe();
    };
    HeaderBreadcrumbs.prototype.componentWillUnmount = function () {
        this.unsubscribe();
    };
    HeaderBreadcrumbs.prototype.render = function () {
        var breadcrumbs = this.state.breadcrumbs;
        if (breadcrumbs.length === 0 && this.props.appTitle) {
            breadcrumbs = [{ text: this.props.appTitle }];
        }
        return React.createElement(EuiHeaderBreadcrumbs, { breadcrumbs: breadcrumbs });
    };
    HeaderBreadcrumbs.prototype.subscribe = function () {
        var _this = this;
        this.subscription = this.props.breadcrumbs$.subscribe(function (breadcrumbs) {
            _this.setState({
                breadcrumbs: breadcrumbs,
            });
        });
    };
    HeaderBreadcrumbs.prototype.unsubscribe = function () {
        if (this.subscription) {
            this.subscription.unsubscribe();
            delete this.subscription;
        }
    };
    return HeaderBreadcrumbs;
}(Component));
export { HeaderBreadcrumbs };
