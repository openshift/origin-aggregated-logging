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
import classNames from 'classnames';
import _ from 'lodash';
import { compact, debounce, get, isEqual } from 'lodash';
import React, { Component } from 'react';
import { getFromLegacyIndexPattern } from 'ui/index_patterns/static_utils';
import { kfetch } from 'ui/kfetch';
import { PersistedLog } from 'ui/persisted_log';
import { timeHistory } from 'ui/timefilter/time_history';
import { getAutocompleteProvider, } from '../../autocomplete_providers';
import chrome from '../../chrome';
import { fromUser, toUser } from '../../parse_query';
import { matchPairs } from '../lib/match_pairs';
import { QueryLanguageSwitcher } from './language_switcher';
import { SuggestionsComponent } from './typeahead/suggestions_component';
import { EuiFieldText, EuiFlexGroup, EuiFlexItem, EuiOutsideClickDetector } from '@elastic/eui';
// @ts-ignore
import { EuiSuperDatePicker, EuiSuperUpdateButton } from '@elastic/eui';
import { injectI18n } from '@kbn/i18n/react';
var KEY_CODES = {
    LEFT: 37,
    UP: 38,
    RIGHT: 39,
    DOWN: 40,
    ENTER: 13,
    ESC: 27,
    TAB: 9,
    HOME: 36,
    END: 35,
};
var config = chrome.getUiSettingsClient();
var recentSearchType = 'recentSearch';
var QueryBarUI = /** @class */ (function (_super) {
    tslib_1.__extends(QueryBarUI, _super);
    function QueryBarUI() {
        var _this = _super !== null && _super.apply(this, arguments) || this;
        /*
         Keep the "draft" value in local state until the user actually submits the query. There are a couple advantages:
      
          1. Each app doesn't have to maintain its own "draft" value if it wants to put off updating the query in app state
          until the user manually submits their changes. Most apps have watches on the query value in app state so we don't
          want to trigger those on every keypress. Also, some apps (e.g. dashboard) already juggle multiple query values,
          each with slightly different semantics and I'd rather not add yet another variable to the mix.
      
          2. Changes to the local component state won't trigger an Angular digest cycle. Triggering digest cycles on every
          keypress has been a major source of performance issues for us in previous implementations of the query bar.
          See https://github.com/elastic/kibana/issues/14086
        */
        _this.state = {
            query: {
                query: toUser(_this.props.query.query),
                language: _this.props.query.language,
            },
            inputIsPristine: true,
            isSuggestionsVisible: false,
            currentProps: _this.props,
            index: null,
            suggestions: [],
            suggestionLimit: 50,
            dateRangeFrom: _.get(_this.props, 'dateRangeFrom', 'now-15m'),
            dateRangeTo: _.get(_this.props, 'dateRangeTo', 'now'),
            isDateRangeInvalid: false,
        };
        _this.updateSuggestions = debounce(function () { return tslib_1.__awaiter(_this, void 0, void 0, function () {
            var suggestions;
            return tslib_1.__generator(this, function (_a) {
                switch (_a.label) {
                    case 0: return [4 /*yield*/, this.getSuggestions()];
                    case 1:
                        suggestions = (_a.sent()) || [];
                        if (!this.componentIsUnmounting) {
                            this.setState({ suggestions: suggestions });
                        }
                        return [2 /*return*/];
                }
            });
        }); }, 100);
        _this.inputRef = null;
        _this.componentIsUnmounting = false;
        _this.persistedLog = null;
        _this.isDirty = function () {
            if (!_this.props.showDatePicker) {
                return _this.state.query.query !== _this.props.query.query;
            }
            return (_this.state.query.query !== _this.props.query.query ||
                _this.state.dateRangeFrom !== _this.props.dateRangeFrom ||
                _this.state.dateRangeTo !== _this.props.dateRangeTo);
        };
        _this.increaseLimit = function () {
            _this.setState({
                suggestionLimit: _this.state.suggestionLimit + 50,
            });
        };
        _this.incrementIndex = function (currentIndex) {
            var nextIndex = currentIndex + 1;
            if (currentIndex === null || nextIndex >= _this.state.suggestions.length) {
                nextIndex = 0;
            }
            _this.setState({ index: nextIndex });
        };
        _this.decrementIndex = function (currentIndex) {
            var previousIndex = currentIndex - 1;
            if (previousIndex < 0) {
                _this.setState({ index: _this.state.suggestions.length - 1 });
            }
            else {
                _this.setState({ index: previousIndex });
            }
        };
        _this.getSuggestions = function () { return tslib_1.__awaiter(_this, void 0, void 0, function () {
            var _a, query, language, recentSearchSuggestions, autocompleteProvider, indexPatterns, getAutocompleteSuggestions, _b, selectionStart, selectionEnd, suggestions;
            return tslib_1.__generator(this, function (_c) {
                switch (_c.label) {
                    case 0:
                        if (!this.inputRef) {
                            return [2 /*return*/];
                        }
                        _a = this.state.query, query = _a.query, language = _a.language;
                        recentSearchSuggestions = this.getRecentSearchSuggestions(query);
                        autocompleteProvider = getAutocompleteProvider(language);
                        if (!autocompleteProvider ||
                            !Array.isArray(this.props.indexPatterns) ||
                            compact(this.props.indexPatterns).length === 0) {
                            return [2 /*return*/, recentSearchSuggestions];
                        }
                        indexPatterns = getFromLegacyIndexPattern(this.props.indexPatterns);
                        getAutocompleteSuggestions = autocompleteProvider({ config: config, indexPatterns: indexPatterns });
                        _b = this.inputRef, selectionStart = _b.selectionStart, selectionEnd = _b.selectionEnd;
                        if (selectionStart === null || selectionEnd === null) {
                            return [2 /*return*/];
                        }
                        return [4 /*yield*/, getAutocompleteSuggestions({
                                query: query,
                                selectionStart: selectionStart,
                                selectionEnd: selectionEnd,
                            })];
                    case 1:
                        suggestions = _c.sent();
                        return [2 /*return*/, tslib_1.__spread(suggestions, recentSearchSuggestions)];
                }
            });
        }); };
        _this.selectSuggestion = function (_a) {
            var type = _a.type, text = _a.text, start = _a.start, end = _a.end;
            if (!_this.inputRef) {
                return;
            }
            var query = _this.state.query.query;
            var _b = _this.inputRef, selectionStart = _b.selectionStart, selectionEnd = _b.selectionEnd;
            if (selectionStart === null || selectionEnd === null) {
                return;
            }
            var value = query.substr(0, selectionStart) + query.substr(selectionEnd);
            _this.setState({
                query: tslib_1.__assign({}, _this.state.query, { query: value.substr(0, start) + text + value.substr(end) }),
                index: null,
            }, function () {
                if (!_this.inputRef) {
                    return;
                }
                _this.inputRef.setSelectionRange(start + text.length, start + text.length);
                if (type === recentSearchType) {
                    _this.onSubmit();
                }
                else {
                    _this.updateSuggestions();
                }
            });
        };
        _this.getRecentSearchSuggestions = function (query) {
            if (!_this.persistedLog) {
                return [];
            }
            var recentSearches = _this.persistedLog.get();
            var matchingRecentSearches = recentSearches.filter(function (recentQuery) {
                var recentQueryString = typeof recentQuery === 'object' ? toUser(recentQuery) : recentQuery;
                return recentQueryString.includes(query);
            });
            return matchingRecentSearches.map(function (recentSearch) {
                var text = recentSearch;
                var start = 0;
                var end = query.length;
                return { type: recentSearchType, text: text, start: start, end: end };
            });
        };
        _this.onOutsideClick = function () {
            if (_this.state.isSuggestionsVisible) {
                _this.setState({ isSuggestionsVisible: false, index: null });
            }
        };
        _this.onClickInput = function (event) {
            if (event.target instanceof HTMLInputElement) {
                _this.onInputChange(event.target.value);
            }
        };
        _this.onClickSubmitButton = function (event) {
            _this.onSubmit(function () { return event.preventDefault(); });
        };
        _this.onClickSuggestion = function (suggestion) {
            if (!_this.inputRef) {
                return;
            }
            _this.selectSuggestion(suggestion);
            _this.inputRef.focus();
        };
        _this.onMouseEnterSuggestion = function (index) {
            _this.setState({ index: index });
        };
        _this.onInputChange = function (value) {
            var hasValue = Boolean(value.trim());
            _this.setState({
                query: {
                    query: value,
                    language: _this.state.query.language,
                },
                inputIsPristine: false,
                isSuggestionsVisible: hasValue,
                index: null,
                suggestionLimit: 50,
            });
        };
        _this.onChange = function (event) {
            _this.updateSuggestions();
            _this.onInputChange(event.target.value);
        };
        _this.onTimeChange = function (_a) {
            var start = _a.start, end = _a.end, isInvalid = _a.isInvalid;
            _this.setState({
                dateRangeFrom: start,
                dateRangeTo: end,
                isDateRangeInvalid: isInvalid,
            });
        };
        _this.onKeyUp = function (event) {
            if ([KEY_CODES.LEFT, KEY_CODES.RIGHT, KEY_CODES.HOME, KEY_CODES.END].includes(event.keyCode)) {
                _this.setState({ isSuggestionsVisible: true });
                if (event.target instanceof HTMLInputElement) {
                    _this.onInputChange(event.target.value);
                }
            }
        };
        _this.onKeyDown = function (event) {
            if (event.target instanceof HTMLInputElement) {
                var _a = _this.state, isSuggestionsVisible = _a.isSuggestionsVisible, index = _a.index;
                var preventDefault = event.preventDefault.bind(event);
                var target_1 = event.target, key = event.key, metaKey = event.metaKey;
                var value = target_1.value, selectionStart = target_1.selectionStart, selectionEnd = target_1.selectionEnd;
                var updateQuery = function (query, newSelectionStart, newSelectionEnd) {
                    _this.setState({
                        query: tslib_1.__assign({}, _this.state.query, { query: query }),
                    }, function () {
                        target_1.setSelectionRange(newSelectionStart, newSelectionEnd);
                    });
                };
                switch (event.keyCode) {
                    case KEY_CODES.DOWN:
                        event.preventDefault();
                        if (isSuggestionsVisible && index !== null) {
                            _this.incrementIndex(index);
                        }
                        else {
                            _this.setState({ isSuggestionsVisible: true, index: 0 });
                        }
                        break;
                    case KEY_CODES.UP:
                        event.preventDefault();
                        if (isSuggestionsVisible && index !== null) {
                            _this.decrementIndex(index);
                        }
                        break;
                    case KEY_CODES.ENTER:
                        event.preventDefault();
                        if (isSuggestionsVisible && index !== null && _this.state.suggestions[index]) {
                            _this.selectSuggestion(_this.state.suggestions[index]);
                        }
                        else {
                            _this.onSubmit(function () { return event.preventDefault(); });
                        }
                        break;
                    case KEY_CODES.ESC:
                        event.preventDefault();
                        _this.setState({ isSuggestionsVisible: false, index: null });
                        break;
                    case KEY_CODES.TAB:
                        _this.setState({ isSuggestionsVisible: false, index: null });
                        break;
                    default:
                        if (selectionStart !== null && selectionEnd !== null) {
                            matchPairs({
                                value: value,
                                selectionStart: selectionStart,
                                selectionEnd: selectionEnd,
                                key: key,
                                metaKey: metaKey,
                                updateQuery: updateQuery,
                                preventDefault: preventDefault,
                            });
                        }
                        break;
                }
            }
        };
        _this.onSubmit = function (preventDefault) {
            if (preventDefault) {
                preventDefault();
            }
            if (_this.persistedLog) {
                _this.persistedLog.add(_this.state.query.query);
            }
            timeHistory.add({
                from: _this.state.dateRangeFrom,
                to: _this.state.dateRangeTo,
            });
            _this.props.onSubmit({
                query: {
                    query: fromUser(_this.state.query.query),
                    language: _this.state.query.language,
                },
                dateRange: {
                    from: _this.state.dateRangeFrom,
                    to: _this.state.dateRangeTo,
                },
            });
            _this.setState({ isSuggestionsVisible: false });
        };
        _this.onSelectLanguage = function (language) {
            // Send telemetry info every time the user opts in or out of kuery
            // As a result it is important this function only ever gets called in the
            // UI component's change handler.
            kfetch({
                pathname: '/api/kibana/kql_opt_in_telemetry',
                method: 'POST',
                body: JSON.stringify({ opt_in: language === 'kuery' }),
            });
            _this.props.store.set('kibana.userQueryLanguage', language);
            _this.props.onSubmit({
                query: {
                    query: '',
                    language: language,
                },
                dateRange: {
                    from: _this.state.dateRangeFrom,
                    to: _this.state.dateRangeTo,
                },
            });
        };
        return _this;
    }
    QueryBarUI.getDerivedStateFromProps = function (nextProps, prevState) {
        if (isEqual(prevState.currentProps, nextProps)) {
            return null;
        }
        var nextQuery = null;
        if (nextProps.query.query !== prevState.query.query) {
            nextQuery = {
                query: toUser(nextProps.query.query),
                language: nextProps.query.language,
            };
        }
        else if (nextProps.query.language !== prevState.query.language) {
            nextQuery = {
                query: '',
                language: nextProps.query.language,
            };
        }
        var nextDateRange = null;
        if (nextProps.dateRangeFrom !== get(prevState, 'currentProps.dateRangeFrom') ||
            nextProps.dateRangeTo !== get(prevState, 'currentProps.dateRangeTo')) {
            nextDateRange = {
                dateRangeFrom: nextProps.dateRangeFrom,
                dateRangeTo: nextProps.dateRangeTo,
            };
        }
        var nextState = {
            currentProps: nextProps,
        };
        if (nextQuery) {
            nextState.query = nextQuery;
        }
        if (nextDateRange) {
            nextState.dateRangeFrom = nextDateRange.dateRangeFrom;
            nextState.dateRangeTo = nextDateRange.dateRangeTo;
        }
        return nextState;
    };
    QueryBarUI.prototype.componentDidMount = function () {
        this.persistedLog = new PersistedLog("typeahead:" + this.props.appName + "-" + this.state.query.language, {
            maxLength: config.get('history:limit'),
            filterDuplicates: true,
        });
        this.updateSuggestions();
    };
    QueryBarUI.prototype.componentDidUpdate = function (prevProps) {
        if (prevProps.query.language !== this.props.query.language) {
            this.persistedLog = new PersistedLog("typeahead:" + this.props.appName + "-" + this.state.query.language, {
                maxLength: config.get('history:limit'),
                filterDuplicates: true,
            });
            this.updateSuggestions();
        }
    };
    QueryBarUI.prototype.componentWillUnmount = function () {
        this.updateSuggestions.cancel();
        this.componentIsUnmounting = true;
    };
    QueryBarUI.prototype.render = function () {
        var _this = this;
        var classes = classNames('kbnQueryBar', {
            'kbnQueryBar--withDatePicker': this.props.showDatePicker,
        });
        return (React.createElement(EuiFlexGroup, { className: classes, responsive: this.props.showDatePicker ? true : false, gutterSize: "s" },
            React.createElement(EuiFlexItem, null,
                React.createElement(EuiOutsideClickDetector, { onOutsideClick: this.onOutsideClick },
                    React.createElement("div", { style: { position: 'relative' }, role: "combobox", "aria-haspopup": "true", "aria-expanded": this.state.isSuggestionsVisible, "aria-owns": "kbnTypeahead__items", "aria-controls": "kbnTypeahead__items" },
                        React.createElement("form", { role: "form", name: "queryBarForm" },
                            React.createElement("div", { className: "kuiLocalSearch", role: "search" },
                                React.createElement("div", { className: "kuiLocalSearchAssistedInput" },
                                    React.createElement(EuiFieldText, { className: "kuiLocalSearchAssistedInput__input", placeholder: this.props.intl.formatMessage({
                                            id: 'common.ui.queryBar.searchInputPlaceholder',
                                            defaultMessage: 'Search… (e.g. status:200 AND extension:PHP)',
                                        }), value: this.state.query.query, onKeyDown: this.onKeyDown, onKeyUp: this.onKeyUp, onChange: this.onChange, onClick: this.onClickInput, fullWidth: true, autoFocus: !this.props.disableAutoFocus, inputRef: function (node) {
                                            if (node) {
                                                _this.inputRef = node;
                                            }
                                        }, autoComplete: "off", spellCheck: false, icon: "console", "aria-label": this.props.intl.formatMessage({
                                            id: 'common.ui.queryBar.searchInputAriaLabel',
                                            defaultMessage: 'Search input',
                                        }), type: "text", "data-test-subj": "queryInput", "aria-autocomplete": "list", "aria-controls": "kbnTypeahead__items", "aria-activedescendant": this.state.isSuggestionsVisible ? 'suggestion-' + this.state.index : '', role: "textbox" }),
                                    React.createElement("div", { className: "kuiLocalSearchAssistedInput__assistance" },
                                        React.createElement(QueryLanguageSwitcher, { language: this.state.query.language, onSelectLanguage: this.onSelectLanguage }))))),
                        React.createElement(SuggestionsComponent, { show: this.state.isSuggestionsVisible, suggestions: this.state.suggestions.slice(0, this.state.suggestionLimit), index: this.state.index, onClick: this.onClickSuggestion, onMouseEnter: this.onMouseEnterSuggestion, loadMore: this.increaseLimit })))),
            React.createElement(EuiFlexItem, { grow: false }, this.renderUpdateButton())));
    };
    QueryBarUI.prototype.renderUpdateButton = function () {
        var button = (React.createElement(EuiSuperUpdateButton, { needsUpdate: this.isDirty(), isDisabled: this.state.isDateRangeInvalid, onClick: this.onClickSubmitButton, "data-test-subj": "querySubmitButton" }));
        if (this.props.showDatePicker) {
            return (React.createElement(EuiFlexGroup, { responsive: false, gutterSize: "s" },
                this.renderDatePicker(),
                React.createElement(EuiFlexItem, { grow: false }, button)));
        }
        else {
            return button;
        }
    };
    QueryBarUI.prototype.renderDatePicker = function () {
        if (!this.props.showDatePicker) {
            return null;
        }
        var recentlyUsedRanges = timeHistory
            .get()
            .map(function (_a) {
            var from = _a.from, to = _a.to;
            return {
                start: from,
                end: to,
            };
        });
        var commonlyUsedRanges = config
            .get('timepicker:quickRanges')
            .map(function (_a) {
            var from = _a.from, to = _a.to, display = _a.display;
            return {
                start: from,
                end: to,
                label: display,
            };
        });
        return (React.createElement(EuiFlexItem, { className: "kbnQueryBar__datePickerWrapper" },
            React.createElement(EuiSuperDatePicker, { start: this.state.dateRangeFrom, end: this.state.dateRangeTo, isPaused: this.props.isRefreshPaused, refreshInterval: this.props.refreshInterval, onTimeChange: this.onTimeChange, onRefreshChange: this.props.onRefreshChange, showUpdateButton: false, recentlyUsedRanges: recentlyUsedRanges, commonlyUsedRanges: commonlyUsedRanges, dateFormat: config.get('dateFormat') })));
    };
    return QueryBarUI;
}(Component));
export { QueryBarUI };
// @ts-ignore
export var QueryBar = injectI18n(QueryBarUI);
