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
import { isEmpty } from 'lodash';
import React, { Component } from 'react';
import { SuggestionComponent } from './suggestion_component';
var SuggestionsComponent = /** @class */ (function (_super) {
    tslib_1.__extends(SuggestionsComponent, _super);
    function SuggestionsComponent() {
        var _this = _super !== null && _super.apply(this, arguments) || this;
        _this.childNodes = [];
        _this.parentNode = null;
        _this.scrollIntoView = function () {
            if (_this.props.index === null) {
                return;
            }
            var parent = _this.parentNode;
            var child = _this.childNodes[_this.props.index];
            if (_this.props.index == null || !parent || !child) {
                return;
            }
            var scrollTop = Math.max(Math.min(parent.scrollTop, child.offsetTop), child.offsetTop + child.offsetHeight - parent.offsetHeight);
            parent.scrollTop = scrollTop;
        };
        _this.handleScroll = function () {
            if (!_this.props.loadMore || !_this.parentNode) {
                return;
            }
            var position = _this.parentNode.scrollTop + _this.parentNode.offsetHeight;
            var height = _this.parentNode.scrollHeight;
            var remaining = height - position;
            var margin = 50;
            if (!height || !position) {
                return;
            }
            if (remaining <= margin) {
                _this.props.loadMore();
            }
        };
        return _this;
    }
    SuggestionsComponent.prototype.render = function () {
        var _this = this;
        if (!this.props.show || isEmpty(this.props.suggestions)) {
            return null;
        }
        var suggestions = this.props.suggestions.map(function (suggestion, index) {
            return (React.createElement(SuggestionComponent, { innerRef: function (node) { return (_this.childNodes[index] = node); }, selected: index === _this.props.index, suggestion: suggestion, onClick: _this.props.onClick, onMouseEnter: function () { return _this.props.onMouseEnter(index); }, ariaId: 'suggestion-' + index, key: suggestion.type + " - " + suggestion.text }));
        });
        return (React.createElement("div", { className: "reactSuggestionTypeahead" },
            React.createElement("div", { className: "kbnTypeahead" },
                React.createElement("div", { className: "kbnTypeahead__popover" },
                    React.createElement("div", { id: "kbnTypeahead__items", className: "kbnTypeahead__items", role: "listbox", ref: function (node) { return (_this.parentNode = node); }, onScroll: this.handleScroll }, suggestions)))));
    };
    SuggestionsComponent.prototype.componentDidUpdate = function (prevProps) {
        if (prevProps.index !== this.props.index) {
            this.scrollIntoView();
        }
    };
    return SuggestionsComponent;
}(Component));
export { SuggestionsComponent };
