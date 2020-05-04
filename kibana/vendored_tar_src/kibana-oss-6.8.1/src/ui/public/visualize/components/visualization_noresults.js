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
import { dispatchRenderComplete } from '../../render_complete';
var VisualizationNoResults = /** @class */ (function (_super) {
    tslib_1.__extends(VisualizationNoResults, _super);
    function VisualizationNoResults() {
        var _this = _super !== null && _super.apply(this, arguments) || this;
        _this.containerDiv = React.createRef();
        return _this;
    }
    VisualizationNoResults.prototype.render = function () {
        return (React.createElement("div", { className: "text-center visError visChart", ref: this.containerDiv },
            React.createElement("div", { className: "item top" }),
            React.createElement("div", { className: "item" },
                React.createElement("h2", { "aria-hidden": "true" },
                    React.createElement("i", { "aria-hidden": "true", className: "fa fa-meh-o" })),
                React.createElement("h4", null, "No results found")),
            React.createElement("div", { className: "item bottom" })));
    };
    VisualizationNoResults.prototype.componentDidMount = function () {
        this.afterRender();
    };
    VisualizationNoResults.prototype.componentDidUpdate = function () {
        this.afterRender();
    };
    VisualizationNoResults.prototype.afterRender = function () {
        if (this.props.onInit) {
            this.props.onInit();
        }
        if (this.containerDiv.current) {
            dispatchRenderComplete(this.containerDiv.current);
        }
    };
    return VisualizationNoResults;
}(React.Component));
export { VisualizationNoResults };
