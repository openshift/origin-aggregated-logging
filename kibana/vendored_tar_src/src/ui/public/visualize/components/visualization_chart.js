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
import React from 'react';
import * as Rx from 'rxjs';
import { debounceTime, filter, share, switchMap, tap } from 'rxjs/operators';
import { dispatchRenderComplete, dispatchRenderStart } from '../../render_complete';
import { ResizeChecker } from '../../resize_checker';
import { getUpdateStatus } from '../../vis/update_status';
var VisualizationChart = /** @class */ (function (_super) {
    tslib_1.__extends(VisualizationChart, _super);
    function VisualizationChart(props) {
        var _this = _super.call(this, props) || this;
        _this.chartDiv = React.createRef();
        _this.containerDiv = React.createRef();
        _this.renderSubject = new Rx.Subject();
        var render$ = _this.renderSubject.asObservable().pipe(share());
        var success$ = render$.pipe(tap(function () {
            if (_this.chartDiv.current) {
                dispatchRenderStart(_this.chartDiv.current);
            }
        }), filter(function (_a) {
            var vis = _a.vis, visData = _a.visData, container = _a.container;
            return vis && container && (!vis.type.requiresSearch || visData);
        }), debounceTime(100), switchMap(function (_a) {
            var vis = _a.vis, visData = _a.visData, container = _a.container;
            return tslib_1.__awaiter(_this, void 0, void 0, function () {
                var status;
                return tslib_1.__generator(this, function (_b) {
                    if (!this.visualization) {
                        // This should never happen, since we only should trigger another rendering
                        // after this component has mounted and thus the visualization implementation
                        // has been initialized
                        throw new Error('Visualization implementation was not initialized on first render.');
                    }
                    vis.size = [container.clientWidth, container.clientHeight];
                    status = getUpdateStatus(vis.type.requiresUpdateStatus, this, this.props);
                    return [2 /*return*/, this.visualization.render(visData, status)];
                });
            });
        }));
        var requestError$ = render$.pipe(filter(function (_a) {
            var vis = _a.vis;
            return vis.requestError;
        }));
        _this.renderSubscription = Rx.merge(success$, requestError$).subscribe(function () {
            if (_this.chartDiv.current !== null) {
                dispatchRenderComplete(_this.chartDiv.current);
            }
        });
        return _this;
    }
    VisualizationChart.prototype.render = function () {
        return (React.createElement("div", { className: "visChart__container", tabIndex: 0, ref: this.containerDiv },
            React.createElement("p", { className: "euiScreenReaderOnly" },
                this.props.vis.type.title,
                " visualization, not yet accessible"),
            React.createElement("div", { "aria-hidden": !this.props.vis.type.isAccessible, className: "visChart", ref: this.chartDiv })));
    };
    VisualizationChart.prototype.componentDidMount = function () {
        var _this = this;
        if (!this.chartDiv.current || !this.containerDiv.current) {
            throw new Error('chartDiv and currentDiv reference should always be present.');
        }
        var _a = this.props, vis = _a.vis, onInit = _a.onInit;
        var Visualization = vis.type.visualization;
        this.visualization = new Visualization(this.chartDiv.current, vis);
        if (onInit) {
            // In case the visualization implementation has an isLoaded function, we
            // call that and wait for the result to resolve (in case it was a promise).
            var visLoaded = this.visualization.isLoaded && this.visualization.isLoaded();
            Promise.resolve(visLoaded).then(onInit);
        }
        // We know that containerDiv.current will never be null, since we will always
        // have rendered and the div is always rendered into the tree (i.e. not
        // inside any condition).
        this.resizeChecker = new ResizeChecker(this.containerDiv.current);
        this.resizeChecker.on('resize', function () { return _this.startRenderVisualization(); });
        this.startRenderVisualization();
    };
    VisualizationChart.prototype.componentDidUpdate = function () {
        this.startRenderVisualization();
    };
    VisualizationChart.prototype.componentWillUnmount = function () {
        if (this.renderSubscription) {
            this.renderSubscription.unsubscribe();
        }
        if (this.resizeChecker) {
            this.resizeChecker.destroy();
        }
        if (this.visualization) {
            this.visualization.destroy();
        }
    };
    VisualizationChart.prototype.startRenderVisualization = function () {
        if (this.containerDiv.current && this.chartDiv.current) {
            this.renderSubject.next({
                vis: this.props.vis,
                visData: this.props.visData,
                container: this.containerDiv.current,
            });
        }
    };
    return VisualizationChart;
}(React.Component));
export { VisualizationChart };
