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
import { EuiText } from '@elastic/eui';
import React from 'react';
import { dispatchRenderComplete } from '../../render_complete';
var VisualizationRequestError = /** @class */ (function (_super) {
    tslib_1.__extends(VisualizationRequestError, _super);
    function VisualizationRequestError() {
        var _this = _super !== null && _super.apply(this, arguments) || this;
        _this.containerDiv = React.createRef();
        return _this;
    }
    VisualizationRequestError.prototype.render = function () {
        var error = this.props.error;
        var errorMessage = (error && error.message) || error;
        return (React.createElement("div", { className: "visError visChart", ref: this.containerDiv },
            React.createElement(EuiText, { className: "visError--request", color: "danger", size: "xs" }, errorMessage)));
    };
    VisualizationRequestError.prototype.componentDidMount = function () {
        this.afterRender();
    };
    VisualizationRequestError.prototype.componentDidUpdate = function () {
        this.afterRender();
    };
    VisualizationRequestError.prototype.afterRender = function () {
        if (this.props.onInit) {
            this.props.onInit();
        }
        if (this.containerDiv.current) {
            dispatchRenderComplete(this.containerDiv.current);
        }
    };
    return VisualizationRequestError;
}(React.Component));
export { VisualizationRequestError };
