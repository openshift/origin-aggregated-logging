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
import { EventEmitter } from 'events';
import { debounce, forEach } from 'lodash';
import * as Rx from 'rxjs';
import { share } from 'rxjs/operators';
import { Inspector } from '../../inspector';
import { RenderCompleteHelper } from '../../render_complete';
import { timefilter } from '../../timefilter';
import { visualizationLoader } from './visualization_loader';
import { VisualizeDataLoader } from './visualize_data_loader';
import { DataAdapter, RequestAdapter } from '../../inspector/adapters';
import { queryGeohashBounds } from './utils';
var RENDER_COMPLETE_EVENT = 'render_complete';
var LOADING_ATTRIBUTE = 'data-loading';
var RENDERING_COUNT_ATTRIBUTE = 'data-rendering-count';
/**
 * A handler to the embedded visualization. It offers several methods to interact
 * with the visualization.
 */
var EmbeddedVisualizeHandler = /** @class */ (function () {
    function EmbeddedVisualizeHandler(element, savedObject, params) {
        var _this = this;
        this.element = element;
        this.inspectorAdapters = {};
        this.loaded = false;
        this.destroyed = false;
        this.listeners = new EventEmitter();
        this.shouldForceNextFetch = false;
        this.debouncedFetchAndRender = debounce(function () {
            if (_this.destroyed) {
                return;
            }
            var forceFetch = _this.shouldForceNextFetch;
            _this.shouldForceNextFetch = false;
            _this.fetch(forceFetch).then(_this.render);
        }, 100);
        this.actions = {};
        /**
         * renders visualization with provided data
         * @param visData: visualization data
         */
        this.render = function (visData) {
            if (visData === void 0) { visData = null; }
            return visualizationLoader
                .render(_this.element, _this.vis, visData, _this.uiState, {
                listenOnChange: false,
            })
                .then(function () {
                if (!_this.loaded) {
                    _this.loaded = true;
                    if (_this.autoFetch) {
                        _this.fetchAndRender();
                    }
                }
            });
        };
        /**
         * Opens the inspector for the embedded visualization. This will return an
         * handler to the inspector to close and interact with it.
         * @return An inspector session to interact with the opened inspector.
         */
        this.openInspector = function () {
            return Inspector.open(_this.inspectorAdapters, {
                title: _this.vis.title,
            });
        };
        this.hasInspector = function () {
            return Inspector.isAvailable(_this.inspectorAdapters);
        };
        /**
         * Force the fetch of new data and renders the chart again.
         */
        this.reload = function () {
            _this.fetchAndRender(true);
        };
        this.incrementRenderingCount = function () {
            var renderingCount = Number(_this.element.getAttribute(RENDERING_COUNT_ATTRIBUTE) || 0);
            _this.element.setAttribute(RENDERING_COUNT_ATTRIBUTE, "" + (renderingCount + 1));
        };
        this.onRenderCompleteListener = function () {
            _this.listeners.emit(RENDER_COMPLETE_EVENT);
            _this.element.removeAttribute(LOADING_ATTRIBUTE);
            _this.incrementRenderingCount();
        };
        this.onUiStateChange = function () {
            _this.fetchAndRender();
        };
        /**
         * Returns an object of all inspectors for this vis object.
         * This must only be called after this.type has properly be initialized,
         * since we need to read out data from the the vis type to check which
         * inspectors are available.
         */
        this.getActiveInspectorAdapters = function () {
            var adapters = {};
            var typeAdapters = _this.vis.type.inspectorAdapters;
            // Add the requests inspector adapters if the vis type explicitly requested it via
            // inspectorAdapters.requests: true in its definition or if it's using the courier
            // request handler, since that will automatically log its requests.
            if ((typeAdapters && typeAdapters.requests) || _this.vis.type.requestHandler === 'courier') {
                adapters.requests = new RequestAdapter();
            }
            // Add the data inspector adapter if the vis type requested it or if the
            // vis is using courier, since we know that courier supports logging
            // its data.
            if ((typeAdapters && typeAdapters.data) || _this.vis.type.requestHandler === 'courier') {
                adapters.data = new DataAdapter();
            }
            // Add all inspectors, that are explicitly registered with this vis type
            if (typeAdapters && typeAdapters.custom) {
                Object.entries(typeAdapters.custom).forEach(function (_a) {
                    var _b = tslib_1.__read(_a, 2), key = _b[0], Adapter = _b[1];
                    adapters[key] = new Adapter();
                });
            }
            return adapters;
        };
        /**
         * Fetches new data and renders the chart. This will happen debounced for a couple
         * of milliseconds, to bundle fast successive calls into one fetch and render,
         * e.g. while resizing the window, this will be triggered constantly on the resize
         * event.
         *
         * @param  forceFetch=false Whether the request handler should be signaled to forceFetch
         *    (i.e. ignore caching in case it supports it). If at least one call to this
         *    passed `true` the debounced fetch and render will be a force fetch.
         */
        this.fetchAndRender = function (forceFetch) {
            if (forceFetch === void 0) { forceFetch = false; }
            _this.shouldForceNextFetch = forceFetch || _this.shouldForceNextFetch;
            _this.element.setAttribute(LOADING_ATTRIBUTE, '');
            _this.debouncedFetchAndRender();
        };
        this.handleVisUpdate = function () {
            if (_this.appState) {
                _this.appState.vis = _this.vis.getState();
                _this.appState.save();
            }
            _this.fetchAndRender();
        };
        this.fetch = function (forceFetch) {
            if (forceFetch === void 0) { forceFetch = false; }
            _this.dataLoaderParams.aggs = _this.vis.getAggConfig();
            _this.dataLoaderParams.forceFetch = forceFetch;
            _this.dataLoaderParams.inspectorAdapters = _this.inspectorAdapters;
            return _this.dataLoader.fetch(_this.dataLoaderParams).then(function (data) {
                _this.dataSubject.next(data);
                return data;
            });
        };
        var searchSource = savedObject.searchSource, vis = savedObject.vis;
        var appState = params.appState, uiState = params.uiState, queryFilter = params.queryFilter, timeRange = params.timeRange, filters = params.filters, query = params.query, _a = params.autoFetch, autoFetch = _a === void 0 ? true : _a, Private = params.Private;
        this.dataLoaderParams = {
            searchSource: searchSource,
            timeRange: timeRange,
            query: query,
            queryFilter: queryFilter,
            filters: filters,
            uiState: uiState,
            aggs: vis.getAggConfig(),
            forceFetch: false,
        };
        // Listen to the first RENDER_COMPLETE_EVENT to resolve this promise
        this.firstRenderComplete = new Promise(function (resolve) {
            _this.listeners.once(RENDER_COMPLETE_EVENT, resolve);
        });
        element.setAttribute(LOADING_ATTRIBUTE, '');
        element.setAttribute(RENDERING_COUNT_ATTRIBUTE, '0');
        element.addEventListener('renderComplete', this.onRenderCompleteListener);
        this.autoFetch = autoFetch;
        this.appState = appState;
        this.vis = vis;
        if (uiState) {
            vis._setUiState(uiState);
        }
        this.uiState = this.vis.getUiState();
        this.vis.on('update', this.handleVisUpdate);
        this.vis.on('reload', this.reload);
        this.uiState.on('change', this.onUiStateChange);
        if (autoFetch) {
            timefilter.on('autoRefreshFetch', this.reload);
        }
        // This is a hack to give maps visualizations access to data in the
        // globalState, since they can no longer access it via searchSource.
        // TODO: Remove this as a part of elastic/kibana#30593
        this.vis.API.getGeohashBounds = function () {
            return queryGeohashBounds(_this.vis, {
                filters: _this.dataLoaderParams.filters,
                query: _this.dataLoaderParams.query,
            });
        };
        this.dataLoader = new VisualizeDataLoader(vis, Private);
        this.renderCompleteHelper = new RenderCompleteHelper(element);
        this.inspectorAdapters = this.getActiveInspectorAdapters();
        this.vis.openInspector = this.openInspector;
        this.vis.hasInspector = this.hasInspector;
        // init default actions
        forEach(this.vis.type.events, function (event, eventName) {
            if (event.disabled || !eventName) {
                return;
            }
            else {
                _this.actions[eventName] = event.defaultAction;
            }
        });
        this.vis.eventsSubject = new Rx.Subject();
        this.events$ = this.vis.eventsSubject.asObservable().pipe(share());
        this.events$.subscribe(function (event) {
            if (_this.actions[event.name]) {
                _this.actions[event.name](event.data);
            }
        });
        this.dataSubject = new Rx.Subject();
        this.data$ = this.dataSubject.asObservable().pipe(share());
        this.render();
    }
    /**
     * Update properties of the embedded visualization. This method does not allow
     * updating all initial parameters, but only a subset of the ones allowed
     * in {@link VisualizeUpdateParams}.
     *
     * @param params The parameters that should be updated.
     */
    EmbeddedVisualizeHandler.prototype.update = function (params) {
        var _this = this;
        if (params === void 0) { params = {}; }
        // Apply data- attributes to the element if specified
        var dataAttrs = params.dataAttrs;
        if (dataAttrs) {
            Object.keys(dataAttrs).forEach(function (key) {
                if (dataAttrs[key] === null) {
                    _this.element.removeAttribute("data-" + key);
                    return;
                }
                _this.element.setAttribute("data-" + key, dataAttrs[key]);
            });
        }
        var fetchRequired = false;
        if (params.hasOwnProperty('timeRange')) {
            fetchRequired = true;
            this.dataLoaderParams.timeRange = params.timeRange;
        }
        if (params.hasOwnProperty('filters')) {
            fetchRequired = true;
            this.dataLoaderParams.filters = params.filters;
        }
        if (params.hasOwnProperty('query')) {
            fetchRequired = true;
            this.dataLoaderParams.query = params.query;
        }
        if (fetchRequired) {
            this.fetchAndRender();
        }
    };
    /**
     * Destroy the underlying Angular scope of the visualization. This should be
     * called whenever you remove the visualization.
     */
    EmbeddedVisualizeHandler.prototype.destroy = function () {
        this.destroyed = true;
        this.debouncedFetchAndRender.cancel();
        if (this.autoFetch) {
            timefilter.off('autoRefreshFetch', this.reload);
        }
        this.vis.removeListener('reload', this.reload);
        this.vis.removeListener('update', this.handleVisUpdate);
        this.element.removeEventListener('renderComplete', this.onRenderCompleteListener);
        this.uiState.off('change', this.onUiStateChange);
        visualizationLoader.destroy(this.element);
        this.renderCompleteHelper.destroy();
    };
    /**
     * Return the actual DOM element (wrapped in jQuery) of the rendered visualization.
     * This is especially useful if you used `append: true` in the parameters where
     * the visualization will be appended to the specified container.
     */
    EmbeddedVisualizeHandler.prototype.getElement = function () {
        return this.element;
    };
    /**
     * Returns a promise, that will resolve (without a value) once the first rendering of
     * the visualization has finished. If you want to listen to consecutive rendering
     * events, look into the `addRenderCompleteListener` method.
     *
     * @returns Promise, that resolves as soon as the visualization is done rendering
     *    for the first time.
     */
    EmbeddedVisualizeHandler.prototype.whenFirstRenderComplete = function () {
        return this.firstRenderComplete;
    };
    /**
     * Adds a listener to be called whenever the visualization finished rendering.
     * This can be called multiple times, when the visualization rerenders, e.g. due
     * to new data.
     *
     * @param {function} listener The listener to be notified about complete renders.
     */
    EmbeddedVisualizeHandler.prototype.addRenderCompleteListener = function (listener) {
        this.listeners.addListener(RENDER_COMPLETE_EVENT, listener);
    };
    /**
     * Removes a previously registered render complete listener from this handler.
     * This listener will no longer be called when the visualization finished rendering.
     *
     * @param {function} listener The listener to remove from this handler.
     */
    EmbeddedVisualizeHandler.prototype.removeRenderCompleteListener = function (listener) {
        this.listeners.removeListener(RENDER_COMPLETE_EVENT, listener);
    };
    return EmbeddedVisualizeHandler;
}());
export { EmbeddedVisualizeHandler };
