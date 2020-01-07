"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const react_1 = tslib_1.__importDefault(require("react"));
const autocomplete_providers_1 = require("ui/autocomplete_providers");
class WithKueryAutocompletion extends react_1.default.Component {
    constructor() {
        super(...arguments);
        this.state = {
            currentRequest: null,
            suggestions: [],
        };
        this.loadSuggestions = async (expression, cursorPosition, maxSuggestions) => {
            const { indexPattern } = this.props;
            const autocompletionProvider = autocomplete_providers_1.getAutocompleteProvider('kuery');
            const config = {
                get: () => true,
            };
            if (!autocompletionProvider) {
                return;
            }
            const getSuggestions = autocompletionProvider({
                config,
                indexPatterns: [indexPattern],
                boolFilter: [],
            });
            this.setState({
                currentRequest: {
                    expression,
                    cursorPosition,
                },
                suggestions: [],
            });
            const suggestions = await getSuggestions({
                query: expression,
                selectionStart: cursorPosition,
                selectionEnd: cursorPosition,
            });
            this.setState(state => state.currentRequest &&
                state.currentRequest.expression !== expression &&
                state.currentRequest.cursorPosition !== cursorPosition
                ? state // ignore this result, since a newer request is in flight
                : {
                    ...state,
                    currentRequest: null,
                    suggestions: maxSuggestions ? suggestions.slice(0, maxSuggestions) : suggestions,
                });
        };
    }
    render() {
        const { currentRequest, suggestions } = this.state;
        return this.props.children({
            isLoadingSuggestions: currentRequest !== null,
            loadSuggestions: this.loadSuggestions,
            suggestions,
        });
    }
}
exports.WithKueryAutocompletion = WithKueryAutocompletion;
