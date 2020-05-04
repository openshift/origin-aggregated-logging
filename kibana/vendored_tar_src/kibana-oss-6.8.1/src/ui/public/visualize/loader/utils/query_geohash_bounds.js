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
import { toastNotifications } from 'ui/notify';
/**
 * Coordinate map visualization needs to be able to query for the latest geohash
 * bounds when a user clicks the "fit to data" map icon, which requires knowing
 * about global filters & queries. This logic has been extracted here so we can
 * keep `searchSource` out of the vis, but ultimately we need to design a
 * long-term solution for situations like this.
 *
 * TODO: Remove this as a part of elastic/kibana#30593
 */
export function queryGeohashBounds(vis, params) {
    return tslib_1.__awaiter(this, void 0, void 0, function () {
        var agg, searchSource, filters_1, query, esResp, error_1;
        return tslib_1.__generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    agg = vis.getAggConfig().find(function (a) {
                        return get(a, 'type.dslName') === 'geohash_grid';
                    });
                    if (!agg) return [3 /*break*/, 4];
                    searchSource = vis.searchSource.createChild();
                    searchSource.setField('size', 0);
                    searchSource.setField('aggs', function () {
                        var geoBoundsAgg = vis.getAggConfig().createAggConfig({
                            type: 'geo_bounds',
                            enabled: true,
                            params: {
                                field: agg.getField(),
                            },
                            schema: 'metric',
                        }, {
                            addToAggConfigs: false,
                        });
                        return {
                            '1': geoBoundsAgg.toDsl(),
                        };
                    });
                    filters_1 = params.filters, query = params.query;
                    if (filters_1) {
                        searchSource.setField('filter', function () {
                            var activeFilters = tslib_1.__spread(filters_1);
                            var indexPattern = agg.getIndexPattern();
                            var useTimeFilter = !!indexPattern.timeFieldName;
                            if (useTimeFilter) {
                                activeFilters.push(vis.API.timeFilter.createFilter(indexPattern));
                            }
                            return activeFilters;
                        });
                    }
                    if (query) {
                        searchSource.setField('query', query);
                    }
                    _a.label = 1;
                case 1:
                    _a.trys.push([1, 3, , 4]);
                    return [4 /*yield*/, searchSource.fetch()];
                case 2:
                    esResp = _a.sent();
                    return [2 /*return*/, get(esResp, 'aggregations.1.bounds')];
                case 3:
                    error_1 = _a.sent();
                    toastNotifications.addDanger({
                        title: i18n.translate('common.ui.visualize.queryGeohashBounds.unableToGetBoundErrorTitle', {
                            defaultMessage: 'Unable to get bounds',
                        }),
                        text: "" + error_1.message,
                    });
                    return [2 /*return*/];
                case 4: return [2 /*return*/];
            }
        });
    });
}
