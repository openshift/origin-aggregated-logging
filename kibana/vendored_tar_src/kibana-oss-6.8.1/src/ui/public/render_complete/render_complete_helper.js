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
var attributeName = 'data-render-complete';
var RenderCompleteHelper = /** @class */ (function () {
    function RenderCompleteHelper(element) {
        var _this = this;
        this.element = element;
        this.destroy = function () {
            _this.element.removeEventListener('renderStart', _this.start);
            _this.element.removeEventListener('renderComplete', _this.complete);
        };
        this.setup = function () {
            _this.element.setAttribute(attributeName, 'false');
            _this.element.addEventListener('renderStart', _this.start);
            _this.element.addEventListener('renderComplete', _this.complete);
        };
        this.disable = function () {
            _this.element.setAttribute(attributeName, 'disabled');
            _this.destroy();
        };
        this.start = function () {
            _this.element.setAttribute(attributeName, 'false');
            return true;
        };
        this.complete = function () {
            _this.element.setAttribute(attributeName, 'true');
            return true;
        };
        this.setup();
    }
    return RenderCompleteHelper;
}());
export { RenderCompleteHelper };
