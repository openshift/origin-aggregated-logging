"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const classnames_1 = tslib_1.__importDefault(require("classnames"));
const d3_scale_1 = require("d3-scale");
const React = tslib_1.__importStar(require("react"));
const search_marker_1 = require("./search_marker");
class SearchMarkers extends React.PureComponent {
    render() {
        const { buckets, start, end, width, height, jumpToTarget, className } = this.props;
        const classes = classnames_1.default('minimapSearchMarkers', className);
        if (start >= end || height <= 0 || Object.keys(buckets).length <= 0) {
            return null;
        }
        const yScale = d3_scale_1.scaleTime()
            .domain([start, end])
            .range([0, height]);
        return (React.createElement("g", { className: classes }, buckets.map(bucket => (React.createElement("g", { key: bucket.representative.gid, transform: `translate(0, ${yScale(bucket.start)})` },
            React.createElement(search_marker_1.SearchMarker, { bucket: bucket, height: yScale(bucket.end) - yScale(bucket.start), width: width, jumpToTarget: jumpToTarget }))))));
    }
}
exports.SearchMarkers = SearchMarkers;
