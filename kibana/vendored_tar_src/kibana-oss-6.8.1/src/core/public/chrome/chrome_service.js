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
import * as Url from 'url';
import * as Rx from 'rxjs';
import { map, takeUntil } from 'rxjs/operators';
var IS_COLLAPSED_KEY = 'core.chrome.isCollapsed';
function isEmbedParamInHash() {
    var query = Url.parse(String(window.location.hash).slice(1), true).query;
    return Boolean(query.embed);
}
var ChromeService = /** @class */ (function () {
    function ChromeService() {
        this.stop$ = new Rx.ReplaySubject(1);
    }
    ChromeService.prototype.start = function () {
        var _this = this;
        var FORCE_HIDDEN = isEmbedParamInHash();
        var brand$ = new Rx.BehaviorSubject({});
        var isVisible$ = new Rx.BehaviorSubject(true);
        var isCollapsed$ = new Rx.BehaviorSubject(!!localStorage.getItem(IS_COLLAPSED_KEY));
        var applicationClasses$ = new Rx.BehaviorSubject(new Set());
        var breadcrumbs$ = new Rx.BehaviorSubject([]);
        return {
            /**
             * Set the brand configuration. Normally the `logo` property will be rendered as the
             * CSS background for the home link in the chrome navigation, but when the page is
             * rendered in a small window the `smallLogo` will be used and rendered at about
             * 45px wide.
             *
             * example:
             *
             *    chrome.setBrand({
             *      logo: 'url(/plugins/app/logo.png) center no-repeat'
             *      smallLogo: 'url(/plugins/app/logo-small.png) center no-repeat'
             *    })
             *
             */
            setBrand: function (brand) {
                brand$.next(Object.freeze({
                    logo: brand.logo,
                    smallLogo: brand.smallLogo,
                }));
            },
            /**
             * Get an observable of the current brand information.
             */
            getBrand$: function () { return brand$.pipe(takeUntil(_this.stop$)); },
            /**
             * Set the temporary visibility for the chrome. This does nothing if the chrome is hidden
             * by default and should be used to hide the chrome for things like full-screen modes
             * with an exit button.
             */
            setIsVisible: function (visibility) {
                isVisible$.next(visibility);
            },
            /**
             * Get an observable of the current visibility state of the chrome.
             */
            getIsVisible$: function () {
                return isVisible$.pipe(map(function (visibility) { return (FORCE_HIDDEN ? false : visibility); }), takeUntil(_this.stop$));
            },
            /**
             * Set the collapsed state of the chrome navigation.
             */
            setIsCollapsed: function (isCollapsed) {
                isCollapsed$.next(isCollapsed);
                if (isCollapsed) {
                    localStorage.setItem(IS_COLLAPSED_KEY, 'true');
                }
                else {
                    localStorage.removeItem(IS_COLLAPSED_KEY);
                }
            },
            /**
             * Get an observable of the current collapsed state of the chrome.
             */
            getIsCollapsed$: function () { return isCollapsed$.pipe(takeUntil(_this.stop$)); },
            /**
             * Add a className that should be set on the application container.
             */
            addApplicationClass: function (className) {
                var update = new Set(tslib_1.__spread(applicationClasses$.getValue()));
                update.add(className);
                applicationClasses$.next(update);
            },
            /**
             * Remove a className added with `addApplicationClass()`. If className is unknown it is ignored.
             */
            removeApplicationClass: function (className) {
                var update = new Set(tslib_1.__spread(applicationClasses$.getValue()));
                update.delete(className);
                applicationClasses$.next(update);
            },
            /**
             * Get the current set of classNames that will be set on the application container.
             */
            getApplicationClasses$: function () {
                return applicationClasses$.pipe(map(function (set) { return tslib_1.__spread(set); }), takeUntil(_this.stop$));
            },
            /**
             * Get an observable of the current list of breadcrumbs
             */
            getBreadcrumbs$: function () { return breadcrumbs$.pipe(takeUntil(_this.stop$)); },
            /**
             * Override the current set of breadcrumbs
             */
            setBreadcrumbs: function (newBreadcrumbs) {
                breadcrumbs$.next(newBreadcrumbs);
            },
        };
    };
    ChromeService.prototype.stop = function () {
        this.stop$.next();
    };
    return ChromeService;
}());
export { ChromeService };
