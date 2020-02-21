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
import angular from 'angular';
import * as columnActions from 'ui/doc_table/actions/columns';
import { Embeddable, } from 'ui/embeddable';
import { RequestAdapter } from 'ui/inspector/adapters';
import { getTime } from 'ui/timefilter/get_time';
import searchTemplate from './search_template.html';
var SearchEmbeddable = /** @class */ (function (_super) {
    tslib_1.__extends(SearchEmbeddable, _super);
    function SearchEmbeddable(_a) {
        var onEmbeddableStateChanged = _a.onEmbeddableStateChanged, savedSearch = _a.savedSearch, editUrl = _a.editUrl, $rootScope = _a.$rootScope, $compile = _a.$compile;
        var _this = _super.call(this, {
            title: savedSearch.title,
            editUrl: editUrl,
            indexPattern: savedSearch.searchSource.getField('index'),
        }) || this;
        _this.panelTitle = '';
        _this.onEmbeddableStateChanged = onEmbeddableStateChanged;
        _this.savedSearch = savedSearch;
        _this.$rootScope = $rootScope;
        _this.$compile = $compile;
        _this.customization = {};
        _this.inspectorAdaptors = {
            requests: new RequestAdapter(),
        };
        return _this;
    }
    SearchEmbeddable.prototype.getInspectorAdapters = function () {
        return this.inspectorAdaptors;
    };
    SearchEmbeddable.prototype.onContainerStateChanged = function (containerState) {
        this.customization = containerState.embeddableCustomization || {};
        this.filters = containerState.filters;
        this.query = containerState.query;
        this.timeRange = containerState.timeRange;
        this.panelTitle = '';
        if (!containerState.hidePanelTitles) {
            this.panelTitle =
                containerState.customTitle !== undefined
                    ? containerState.customTitle
                    : this.savedSearch.title;
        }
        if (this.searchScope) {
            this.pushContainerStateParamsToScope(this.searchScope);
        }
    };
    /**
     *
     * @param {Element} domNode
     * @param {ContainerState} containerState
     */
    SearchEmbeddable.prototype.render = function (domNode, containerState) {
        this.onContainerStateChanged(containerState);
        this.initializeSearchScope();
        if (!this.searchScope) {
            throw new Error('Search scope not defined');
            return;
        }
        this.searchInstance = this.$compile(searchTemplate)(this.searchScope);
        var rootNode = angular.element(domNode);
        rootNode.append(this.searchInstance);
    };
    SearchEmbeddable.prototype.destroy = function () {
        this.savedSearch.destroy();
        if (this.searchInstance) {
            this.searchInstance.remove();
        }
        if (this.searchScope) {
            this.searchScope.$destroy();
            delete this.searchScope;
        }
    };
    SearchEmbeddable.prototype.initializeSearchScope = function () {
        var _this = this;
        var searchScope = this.$rootScope.$new();
        searchScope.description = this.savedSearch.description;
        searchScope.searchSource = this.savedSearch.searchSource;
        searchScope.inspectorAdapters = this.inspectorAdaptors;
        var timeRangeSearchSource = searchScope.searchSource.create();
        timeRangeSearchSource.setField('filter', function () {
            if (!_this.searchScope || !_this.timeRange) {
                return;
            }
            return getTime(_this.searchScope.searchSource.getField('index'), _this.timeRange);
        });
        this.filtersSearchSource = searchScope.searchSource.create();
        this.filtersSearchSource.setParent(timeRangeSearchSource);
        searchScope.searchSource.setParent(this.filtersSearchSource);
        this.pushContainerStateParamsToScope(searchScope);
        searchScope.setSortOrder = function (columnName, direction) {
            searchScope.sort = _this.customization.sort = [columnName, direction];
            _this.emitEmbeddableStateChange(_this.getEmbeddableState());
        };
        searchScope.addColumn = function (columnName) {
            if (!searchScope.columns) {
                return;
            }
            _this.savedSearch.searchSource.getField('index').popularizeField(columnName, 1);
            columnActions.addColumn(searchScope.columns, columnName);
            searchScope.columns = _this.customization.columns = searchScope.columns;
            _this.emitEmbeddableStateChange(_this.getEmbeddableState());
        };
        searchScope.removeColumn = function (columnName) {
            if (!searchScope.columns) {
                return;
            }
            _this.savedSearch.searchSource.getField('index').popularizeField(columnName, 1);
            columnActions.removeColumn(searchScope.columns, columnName);
            _this.customization.columns = searchScope.columns;
            _this.emitEmbeddableStateChange(_this.getEmbeddableState());
        };
        searchScope.moveColumn = function (columnName, newIndex) {
            if (!searchScope.columns) {
                return;
            }
            columnActions.moveColumn(searchScope.columns, columnName, newIndex);
            _this.customization.columns = searchScope.columns;
            _this.emitEmbeddableStateChange(_this.getEmbeddableState());
        };
        searchScope.filter = function (field, value, operator) {
            var index = _this.savedSearch.searchSource.getField('index').id;
            var stagedFilter = {
                field: field,
                value: value,
                operator: operator,
                index: index,
            };
            _this.emitEmbeddableStateChange(tslib_1.__assign({}, _this.getEmbeddableState(), { stagedFilter: stagedFilter }));
        };
        this.searchScope = searchScope;
    };
    SearchEmbeddable.prototype.emitEmbeddableStateChange = function (embeddableState) {
        this.onEmbeddableStateChanged(embeddableState);
    };
    SearchEmbeddable.prototype.getEmbeddableState = function () {
        return {
            customization: this.customization,
        };
    };
    SearchEmbeddable.prototype.pushContainerStateParamsToScope = function (searchScope) {
        // If there is column or sort data on the panel, that means the original columns or sort settings have
        // been overridden in a dashboard.
        searchScope.columns = this.customization.columns || this.savedSearch.columns;
        searchScope.sort = this.customization.sort || this.savedSearch.sort;
        searchScope.sharedItemTitle = this.panelTitle;
        this.filtersSearchSource.setField('filter', this.filters);
        this.filtersSearchSource.setField('query', this.query);
    };
    return SearchEmbeddable;
}(Embeddable));
export { SearchEmbeddable };
