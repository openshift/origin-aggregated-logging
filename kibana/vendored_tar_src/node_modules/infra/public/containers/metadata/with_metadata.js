"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const lodash_1 = tslib_1.__importDefault(require("lodash"));
const react_1 = tslib_1.__importDefault(require("react"));
const react_apollo_1 = require("react-apollo");
const metadata_gql_query_1 = require("./metadata.gql_query");
exports.WithMetadata = ({ children, layouts, nodeType, nodeId, sourceId, }) => {
    return (react_1.default.createElement(react_apollo_1.Query, { query: metadata_gql_query_1.metadataQuery, fetchPolicy: "no-cache", variables: {
            sourceId,
            nodeType,
            nodeId,
        } }, ({ data, error, loading }) => {
        const metadata = data && data.source && data.source.metadataByNode;
        const filteredLayouts = (metadata && getFilteredLayouts(layouts, metadata.features)) || [];
        return children({
            name: (metadata && metadata.name) || '',
            filteredLayouts,
            error: error && error.message,
            loading,
        });
    }));
};
const getFilteredLayouts = (layouts, metadata) => {
    if (!metadata) {
        return layouts;
    }
    const metricMetadata = metadata
        .filter(data => data && data.source === 'metrics')
        .map(data => data && data.name);
    // After filtering out sections that can't be displayed, a layout may end up empty and can be removed.
    const filteredLayouts = layouts
        .map(layout => getFilteredLayout(layout, metricMetadata))
        .filter(layout => layout.sections.length > 0);
    return filteredLayouts;
};
const getFilteredLayout = (layout, metricMetadata) => {
    // A section is only displayed if at least one of its requirements is met
    // All others are filtered out.
    const filteredSections = layout.sections.filter(section => lodash_1.default.intersection(section.requires, metricMetadata).length > 0);
    return { ...layout, sections: filteredSections };
};
