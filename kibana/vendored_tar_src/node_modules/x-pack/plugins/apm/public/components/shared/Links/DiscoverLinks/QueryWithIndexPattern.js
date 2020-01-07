"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const react_1 = tslib_1.__importDefault(require("react"));
const savedObjects_1 = require("x-pack/plugins/apm/public/services/rest/savedObjects");
function getQueryWithIndexPattern(query, indexPattern) {
    if ((query._a && query._a.index) || !indexPattern) {
        return query;
    }
    const id = indexPattern && indexPattern.id;
    return {
        ...query,
        _a: {
            ...query._a,
            index: id
        }
    };
}
exports.getQueryWithIndexPattern = getQueryWithIndexPattern;
class QueryWithIndexPattern extends react_1.default.Component {
    constructor(props) {
        super(props);
        savedObjects_1.getAPMIndexPattern().then(indexPattern => {
            this.setState({ indexPattern });
        });
        this.state = {};
    }
    render() {
        const { children, query } = this.props;
        const { indexPattern } = this.state;
        const renderWithQuery = children;
        return renderWithQuery(getQueryWithIndexPattern(query, indexPattern));
    }
}
exports.QueryWithIndexPattern = QueryWithIndexPattern;
