"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const react_1 = tslib_1.__importDefault(require("react"));
const react_redux_1 = require("react-redux");
const store_1 = require("../../store");
const kuery_1 = require("../../utils/kuery");
const typed_react_1 = require("../../utils/typed_react");
const typed_redux_1 = require("../../utils/typed_redux");
const url_state_1 = require("../../utils/url_state");
exports.withWaffleFilter = react_redux_1.connect((state) => ({
    filterQuery: store_1.waffleFilterSelectors.selectWaffleFilterQuery(state),
    filterQueryDraft: store_1.waffleFilterSelectors.selectWaffleFilterQueryDraft(state),
    filterQueryAsJson: store_1.waffleFilterSelectors.selectWaffleFilterQueryAsJson(state),
    isFilterQueryDraftValid: store_1.waffleFilterSelectors.selectIsWaffleFilterQueryDraftValid(state),
}), (dispatch, ownProps) => typed_redux_1.bindPlainActionCreators({
    applyFilterQuery: (query) => store_1.waffleFilterActions.applyWaffleFilterQuery({
        query,
        serializedQuery: kuery_1.convertKueryToElasticSearchQuery(query.expression, ownProps.indexPattern),
    }),
    applyFilterQueryFromKueryExpression: (expression) => store_1.waffleFilterActions.applyWaffleFilterQuery({
        query: {
            kind: 'kuery',
            expression,
        },
        serializedQuery: kuery_1.convertKueryToElasticSearchQuery(expression, ownProps.indexPattern),
    }),
    setFilterQueryDraft: store_1.waffleFilterActions.setWaffleFilterQueryDraft,
    setFilterQueryDraftFromKueryExpression: (expression) => store_1.waffleFilterActions.setWaffleFilterQueryDraft({
        kind: 'kuery',
        expression,
    }),
}));
exports.WithWaffleFilter = typed_react_1.asChildFunctionRenderer(exports.withWaffleFilter);
exports.WithWaffleFilterUrlState = ({ indexPattern, }) => (react_1.default.createElement(exports.WithWaffleFilter, { indexPattern: indexPattern }, ({ applyFilterQuery, filterQuery }) => (react_1.default.createElement(url_state_1.UrlStateContainer, { urlState: filterQuery, urlStateKey: "waffleFilter", mapToUrlState: mapToUrlState, onChange: urlState => {
        if (urlState) {
            applyFilterQuery(urlState);
        }
    }, onInitialize: urlState => {
        if (urlState) {
            applyFilterQuery(urlState);
        }
    } }))));
const mapToUrlState = (value) => value && value.kind === 'kuery' && typeof value.expression === 'string'
    ? {
        kind: value.kind,
        expression: value.expression,
    }
    : undefined;
