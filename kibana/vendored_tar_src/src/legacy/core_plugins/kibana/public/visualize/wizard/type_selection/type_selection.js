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
import { FormattedMessage } from '@kbn/i18n/react';
import { sortByOrder } from 'lodash';
import React from 'react';
import { EuiFieldSearch, EuiFlexGroup, EuiFlexItem, EuiKeyPadMenu, EuiKeyPadMenuItemButton, EuiModalHeader, EuiModalHeaderTitle, EuiScreenReaderOnly, EuiSpacer, EuiTitle, } from '@elastic/eui';
import { NewVisHelp } from './new_vis_help';
import { VisHelpText } from './vis_help_text';
import { VisTypeIcon } from './vis_type_icon';
import { memoizeLast } from 'ui/utils/memoize';
var TypeSelection = /** @class */ (function (_super) {
    tslib_1.__extends(TypeSelection, _super);
    function TypeSelection() {
        var _this = _super !== null && _super.apply(this, arguments) || this;
        _this.state = {
            highlightedType: null,
            query: '',
        };
        _this.getFilteredVisTypes = memoizeLast(_this.filteredVisTypes);
        _this.renderVisType = function (visType) {
            var stage = {};
            if (visType.stage === 'experimental') {
                stage = {
                    betaBadgeLabel: i18n.translate('kbn.visualize.newVisWizard.experimentalTitle', {
                        defaultMessage: 'Experimental',
                    }),
                    betaBadgeTooltipContent: i18n.translate('kbn.visualize.newVisWizard.experimentalTooltip', {
                        defaultMessage: 'This visualization is experimental.',
                    }),
                };
            }
            var isDisabled = _this.state.query !== '' && !visType.highlighted;
            return (React.createElement(EuiKeyPadMenuItemButton, tslib_1.__assign({ key: visType.name, label: React.createElement("span", { "data-test-subj": "visTypeTitle" }, visType.title), onClick: function () { return _this.props.onVisTypeSelected(visType); }, onFocus: function () { return _this.highlightType(visType); }, onMouseEnter: function () { return _this.highlightType(visType); }, onMouseLeave: function () { return _this.highlightType(null); }, onBlur: function () { return _this.highlightType(null); }, className: "visNewVisDialog__type", "data-test-subj": "visType-" + visType.name, "data-vis-stage": visType.stage, disabled: isDisabled, "aria-describedby": "visTypeDescription-" + visType.name }, stage),
                React.createElement(VisTypeIcon, { visType: visType })));
        };
        _this.onQueryChange = function (ev) {
            _this.setState({
                query: ev.target.value,
            });
        };
        return _this;
    }
    TypeSelection.prototype.render = function () {
        var _a = this.state, query = _a.query, highlightedType = _a.highlightedType;
        var visTypes = this.getFilteredVisTypes(this.props.visTypesRegistry, query);
        return (React.createElement(React.Fragment, null,
            React.createElement(EuiModalHeader, null,
                React.createElement(EuiModalHeaderTitle, null,
                    React.createElement(FormattedMessage, { id: "kbn.visualize.newVisWizard.title", defaultMessage: "New Visualization" }))),
            React.createElement("div", { className: "visNewVisDialog__body" },
                React.createElement(EuiFlexGroup, { gutterSize: "xl" },
                    React.createElement(EuiFlexItem, null,
                        React.createElement(EuiFlexGroup, { className: "visNewVisDialog__list", direction: "column", gutterSize: "none", responsive: false },
                            React.createElement(EuiFlexItem, { grow: false, className: "visNewVisDialog__searchWrapper" },
                                React.createElement(EuiFieldSearch, { placeholder: "Filter", value: query, onChange: this.onQueryChange, fullWidth: true, "data-test-subj": "filterVisType", "aria-label": i18n.translate('kbn.visualize.newVisWizard.filterVisTypeAriaLabel', {
                                        defaultMessage: 'Filter for a visualization type',
                                    }) })),
                            React.createElement(EuiFlexItem, { grow: 1, className: "visNewVisDialog__typesWrapper" },
                                React.createElement(EuiScreenReaderOnly, null,
                                    React.createElement("span", { "aria-live": "polite" }, query && (React.createElement(FormattedMessage, { id: "kbn.visualize.newVisWizard.resultsFound", defaultMessage: "{resultCount} {resultCount, plural,\n                            one {type}\n                            other {types}\n                          } found", values: { resultCount: visTypes.filter(function (type) { return type.highlighted; }).length } })))),
                                React.createElement(EuiKeyPadMenu, { className: "visNewVisDialog__types", "data-test-subj": "visNewDialogTypes" }, visTypes.map(this.renderVisType))))),
                    React.createElement(EuiFlexItem, { className: "visNewVisDialog__description", grow: false }, highlightedType ? (React.createElement(VisHelpText, { visType: highlightedType })) : (React.createElement(React.Fragment, null,
                        React.createElement(EuiTitle, { size: "s" },
                            React.createElement("h2", null,
                                React.createElement(FormattedMessage, { id: "kbn.visualize.newVisWizard.selectVisType", defaultMessage: "Select a visualization type" }))),
                        React.createElement(EuiSpacer, { size: "m" }),
                        React.createElement(NewVisHelp, null))))))));
    };
    TypeSelection.prototype.filteredVisTypes = function (visTypes, query) {
        var _this = this;
        var types = visTypes.filter(function (type) {
            // Filter out all lab visualizations if lab mode is not enabled
            if (!_this.props.showExperimental && type.stage === 'experimental') {
                return false;
            }
            // Filter out hidden visualizations
            if (type.hidden) {
                return false;
            }
            return true;
        });
        var entries;
        if (!query) {
            entries = types.map(function (type) { return (tslib_1.__assign({}, type, { highlighted: false })); });
        }
        else {
            var q_1 = query.toLowerCase();
            entries = types.map(function (type) {
                var matchesQuery = type.name.toLowerCase().includes(q_1) ||
                    type.title.toLowerCase().includes(q_1) ||
                    (typeof type.description === 'string' && type.description.toLowerCase().includes(q_1));
                return tslib_1.__assign({}, type, { highlighted: matchesQuery });
            });
        }
        return sortByOrder(entries, ['highlighted', 'title'], ['desc', 'asc']);
    };
    TypeSelection.prototype.highlightType = function (visType) {
        this.setState({
            highlightedType: visType,
        });
    };
    return TypeSelection;
}(React.Component));
export { TypeSelection };
