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
import * as Rx from 'rxjs';
import { distinctUntilChanged, endWith, map, pairwise, startWith, takeUntil, tap, } from 'rxjs/operators';
var LoadingCountService = /** @class */ (function () {
    function LoadingCountService() {
        this.total$ = new Rx.BehaviorSubject(0);
        this.stop$ = new Rx.Subject();
    }
    LoadingCountService.prototype.start = function (_a) {
        var _this = this;
        var fatalErrors = _a.fatalErrors;
        return {
            add: function (count$) {
                count$
                    .pipe(distinctUntilChanged(), tap(function (count) {
                    if (count < 0) {
                        throw new Error('Observables passed to loadingCount.add() must only emit positive numbers');
                    }
                }), 
                // use takeUntil() so that we can finish each stream on stop() the same way we do when they complete,
                // by removing the previous count from the total
                takeUntil(_this.stop$), endWith(0), startWith(0), pairwise(), map(function (_a) {
                    var _b = tslib_1.__read(_a, 2), prev = _b[0], next = _b[1];
                    return next - prev;
                }))
                    .subscribe({
                    next: function (delta) {
                        _this.total$.next(_this.total$.getValue() + delta);
                    },
                    error: function (error) {
                        fatalErrors.add(error);
                    },
                });
            },
            getCount$: function () {
                return _this.total$.pipe(distinctUntilChanged());
            },
        };
    };
    LoadingCountService.prototype.stop = function () {
        this.stop$.next();
        this.total$.complete();
    };
    return LoadingCountService;
}());
export { LoadingCountService };
