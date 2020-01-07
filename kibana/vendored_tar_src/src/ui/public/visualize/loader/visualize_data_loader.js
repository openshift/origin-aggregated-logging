import * as tslib_1 from "tslib";
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
import { isEqual } from 'lodash';
import { VisRequestHandlersRegistryProvider as RequestHandlersProvider } from '../../registry/vis_request_handlers';
import { VisResponseHandlersRegistryProvider as ResponseHandlerProvider } from '../../registry/vis_response_handlers';
// @ts-ignore No typing present
import { isTermSizeZeroError } from '../../elasticsearch_errors';
import { toastNotifications } from 'ui/notify';
function getHandler(from, type) {
    if (typeof type === 'function') {
        return type;
    }
    var handlerDesc = from.find(function (handler) { return handler.name === type; });
    if (!handlerDesc) {
        throw new Error("Could not find handler \"" + type + "\".");
    }
    return handlerDesc.handler;
}
var VisualizeDataLoader = /** @class */ (function () {
    function VisualizeDataLoader(vis, Private) {
        this.vis = vis;
        var _a = vis.type, requestHandler = _a.requestHandler, responseHandler = _a.responseHandler;
        var requestHandlers = Private(RequestHandlersProvider);
        var responseHandlers = Private(ResponseHandlerProvider);
        this.requestHandler = getHandler(requestHandlers, requestHandler);
        this.responseHandler = getHandler(responseHandlers, responseHandler);
    }
    VisualizeDataLoader.prototype.fetch = function (params) {
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            var minimalColumns, filters, savedFilters, query, requestHandlerResponse, canSkipResponseHandler, _a, error_1;
            return tslib_1.__generator(this, function (_b) {
                switch (_b.label) {
                    case 0:
                        this.vis.filters = { timeRange: params.timeRange };
                        this.vis.requestError = undefined;
                        this.vis.showRequestError = false;
                        _b.label = 1;
                    case 1:
                        _b.trys.push([1, 5, , 6]);
                        minimalColumns = typeof this.vis.params.showMetricsAtAllLevels !== 'undefined'
                            ? !this.vis.params.showMetricsAtAllLevels
                            : !this.vis.isHierarchical();
                        filters = params.filters || [];
                        savedFilters = params.searchSource.getField('filter') || [];
                        query = params.query || params.searchSource.getField('query');
                        return [4 /*yield*/, this.requestHandler(tslib_1.__assign({ partialRows: this.vis.type.requiresPartialRows || this.vis.params.showPartialRows, minimalColumns: minimalColumns, metricsAtAllLevels: this.vis.isHierarchical(), visParams: this.vis.params }, params, { query: query, filters: filters.concat(savedFilters).filter(function (f) { return !f.meta.disabled; }) }))];
                    case 2:
                        requestHandlerResponse = _b.sent();
                        canSkipResponseHandler = this.previousRequestHandlerResponse &&
                            this.previousRequestHandlerResponse === requestHandlerResponse &&
                            this.previousVisState &&
                            isEqual(this.previousVisState, this.vis.getState());
                        this.previousVisState = this.vis.getState();
                        this.previousRequestHandlerResponse = requestHandlerResponse;
                        if (!!canSkipResponseHandler) return [3 /*break*/, 4];
                        _a = this;
                        return [4 /*yield*/, Promise.resolve(this.responseHandler(requestHandlerResponse))];
                    case 3:
                        _a.visData = _b.sent();
                        _b.label = 4;
                    case 4: return [2 /*return*/, this.visData];
                    case 5:
                        error_1 = _b.sent();
                        params.searchSource.cancelQueued();
                        this.vis.requestError = error_1;
                        this.vis.showRequestError =
                            error_1.type && ['NO_OP_SEARCH_STRATEGY', 'UNSUPPORTED_QUERY'].includes(error_1.type);
                        // tslint:disable-next-line
                        console.error(error_1);
                        if (isTermSizeZeroError(error_1)) {
                            return [2 /*return*/, toastNotifications.addDanger("Your visualization ('" + this.vis.title + "') has an error: it has a term " +
                                    "aggregation with a size of 0. Please set it to a number greater than 0 to resolve " +
                                    "the error.")];
                        }
                        toastNotifications.addDanger({
                            title: 'Error in visualization',
                            text: error_1.message,
                        });
                        return [3 /*break*/, 6];
                    case 6: return [2 /*return*/];
                }
            });
        });
    };
    return VisualizeDataLoader;
}());
export { VisualizeDataLoader };
