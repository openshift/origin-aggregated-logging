"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const d3_1 = tslib_1.__importDefault(require("d3"));
const moment_1 = tslib_1.__importDefault(require("moment"));
const annotations_1 = require("../../../../common/constants/annotations");
// @ts-ignore
const chart_tooltip_service_1 = require("../../../components/chart_tooltip/chart_tooltip_service");
const annotations_service_1 = require("../../../services/annotations_service");
exports.ANNOTATION_MASK_ID = 'mlAnnotationMask';
// getAnnotationBrush() is expected to be called like getAnnotationBrush.call(this)
// so it gets passed on the context of the component it gets called from.
function getAnnotationBrush() {
    const focusXScale = this.focusXScale;
    const annotateBrush = d3_1.default.svg
        .brush()
        .x(focusXScale)
        .on('brushend', brushend.bind(this));
    // cast a reference to this so we get the latest state when brushend() gets called
    function brushend() {
        const { selectedJob } = this.props;
        // TS TODO make this work with the actual types.
        const extent = annotateBrush.extent();
        const timestamp = extent[0].getTime();
        const endTimestamp = extent[1].getTime();
        if (timestamp === endTimestamp) {
            annotations_service_1.annotation$.next(null);
            return;
        }
        const annotation = {
            timestamp,
            end_timestamp: endTimestamp,
            annotation: '',
            job_id: selectedJob.job_id,
            type: annotations_1.ANNOTATION_TYPE.ANNOTATION,
        };
        annotations_service_1.annotation$.next(annotation);
    }
    return annotateBrush;
}
exports.getAnnotationBrush = getAnnotationBrush;
// Used to resolve overlapping annotations in the UI.
// The returned levels can be used to create a vertical offset.
function getAnnotationLevels(focusAnnotationData) {
    const levels = {};
    focusAnnotationData.forEach((d, i) => {
        if (d.key !== undefined) {
            const longerAnnotations = focusAnnotationData.filter((d2, i2) => i2 < i);
            levels[d.key] = longerAnnotations.reduce((level, d2) => {
                // For now we only support overlap removal for annotations which have both
                // `timestamp` and `end_timestamp` set.
                if (d.end_timestamp === undefined ||
                    d2.end_timestamp === undefined ||
                    d2.key === undefined) {
                    return level;
                }
                if (
                // d2 is completely before d
                (d2.timestamp < d.timestamp && d2.end_timestamp < d.timestamp) ||
                    // d2 is completely after d
                    (d2.timestamp > d.end_timestamp && d2.end_timestamp > d.end_timestamp)) {
                    return level;
                }
                return levels[d2.key] + 1;
            }, 0);
        }
    });
    return levels;
}
exports.getAnnotationLevels = getAnnotationLevels;
const ANNOTATION_DEFAULT_LEVEL = 1;
const ANNOTATION_LEVEL_HEIGHT = 28;
const ANNOTATION_UPPER_RECT_MARGIN = 0;
const ANNOTATION_UPPER_TEXT_MARGIN = -7;
const ANNOTATION_MIN_WIDTH = 2;
const ANNOTATION_RECT_BORDER_RADIUS = 2;
const ANNOTATION_TEXT_VERTICAL_OFFSET = 26;
const ANNOTATION_TEXT_RECT_VERTICAL_OFFSET = 12;
const ANNOTATION_TEXT_RECT_WIDTH = 24;
const ANNOTATION_TEXT_RECT_HEIGHT = 20;
function renderAnnotations(focusChart, focusAnnotationData, focusZoomPanelHeight, focusChartHeight, focusXScale, showAnnotations, showFocusChartTooltip) {
    const upperRectMargin = ANNOTATION_UPPER_RECT_MARGIN;
    const upperTextMargin = ANNOTATION_UPPER_TEXT_MARGIN;
    const durations = {};
    focusAnnotationData.forEach(d => {
        if (d.key !== undefined) {
            const duration = (d.end_timestamp || 0) - d.timestamp;
            durations[d.key] = duration;
        }
    });
    // sort by duration
    focusAnnotationData.sort((a, b) => {
        if (a.key === undefined || b.key === undefined) {
            return 0;
        }
        return durations[b.key] - durations[a.key];
    });
    const levelHeight = ANNOTATION_LEVEL_HEIGHT;
    const levels = getAnnotationLevels(focusAnnotationData);
    const annotations = focusChart
        .select('.mlAnnotations')
        .selectAll('g.mlAnnotation')
        .data(focusAnnotationData || [], (d) => d._id || '');
    annotations
        .enter()
        .append('g')
        .classed('mlAnnotation', true);
    const rects = annotations.selectAll('.mlAnnotationRect').data((d) => [d]);
    rects
        .enter()
        .append('rect')
        .attr('rx', ANNOTATION_RECT_BORDER_RADIUS)
        .attr('ry', ANNOTATION_RECT_BORDER_RADIUS)
        .classed('mlAnnotationRect', true)
        .attr('mask', `url(#${exports.ANNOTATION_MASK_ID})`)
        .on('mouseover', function (d) {
        showFocusChartTooltip(d, this);
    })
        .on('mouseout', () => chart_tooltip_service_1.mlChartTooltipService.hide())
        .on('click', (d) => {
        // clear a possible existing annotation set up for editing before setting the new one.
        // this needs to be done explicitly here because a new annotation created using the brush tool
        // could still be present in the chart.
        annotations_service_1.annotation$.next(null);
        // set the actual annotation and trigger the flyout
        annotations_service_1.annotation$.next(d);
    });
    rects
        .attr('x', (d) => {
        const date = moment_1.default(d.timestamp);
        return focusXScale(date);
    })
        .attr('y', (d) => {
        const level = d.key !== undefined ? levels[d.key] : ANNOTATION_DEFAULT_LEVEL;
        return focusZoomPanelHeight + 1 + upperRectMargin + level * levelHeight;
    })
        .attr('height', (d) => {
        const level = d.key !== undefined ? levels[d.key] : ANNOTATION_DEFAULT_LEVEL;
        return focusChartHeight - 2 - upperRectMargin - level * levelHeight;
    })
        .attr('width', (d) => {
        const s = focusXScale(moment_1.default(d.timestamp)) + 1;
        const e = typeof d.end_timestamp !== 'undefined'
            ? focusXScale(moment_1.default(d.end_timestamp)) - 1
            : s + ANNOTATION_MIN_WIDTH;
        const width = Math.max(ANNOTATION_MIN_WIDTH, e - s);
        return width;
    });
    rects.exit().remove();
    const textRects = annotations.selectAll('.mlAnnotationTextRect').data(d => [d]);
    const texts = annotations.selectAll('.mlAnnotationText').data(d => [d]);
    textRects
        .enter()
        .append('rect')
        .classed('mlAnnotationTextRect', true)
        .attr('width', ANNOTATION_TEXT_RECT_WIDTH)
        .attr('height', ANNOTATION_TEXT_RECT_HEIGHT)
        .attr('rx', ANNOTATION_RECT_BORDER_RADIUS)
        .attr('ry', ANNOTATION_RECT_BORDER_RADIUS);
    texts
        .enter()
        .append('text')
        .classed('mlAnnotationText', true);
    function labelXOffset(ts) {
        const earliestMs = focusXScale.domain()[0];
        const latestMs = focusXScale.domain()[1];
        const date = moment_1.default(ts);
        const minX = Math.max(focusXScale(earliestMs), focusXScale(date));
        // To avoid overflow to the right, substract maxOffset which is
        // the width of the text label (24px) plus left margin (8xp).
        const maxOffset = 32;
        return Math.min(focusXScale(latestMs) - maxOffset, minX);
    }
    texts
        .attr('x', (d) => {
        const leftInnerOffset = 17;
        return labelXOffset(d.timestamp) + leftInnerOffset;
    })
        .attr('y', (d) => {
        const level = d.key !== undefined ? levels[d.key] : ANNOTATION_DEFAULT_LEVEL;
        return (focusZoomPanelHeight +
            upperTextMargin +
            ANNOTATION_TEXT_VERTICAL_OFFSET +
            level * levelHeight);
    })
        .text((d) => d.key);
    textRects
        .attr('x', (d) => {
        const leftInnerOffset = 5;
        return labelXOffset(d.timestamp) + leftInnerOffset;
    })
        .attr('y', (d) => {
        const level = d.key !== undefined ? levels[d.key] : ANNOTATION_DEFAULT_LEVEL;
        return (focusZoomPanelHeight +
            upperTextMargin +
            ANNOTATION_TEXT_RECT_VERTICAL_OFFSET +
            level * levelHeight);
    });
    textRects.exit().remove();
    texts.exit().remove();
    annotations.classed('mlAnnotationHidden', !showAnnotations);
    annotations.exit().remove();
}
exports.renderAnnotations = renderAnnotations;
function highlightFocusChartAnnotation(annotation) {
    const annotations = d3_1.default.selectAll('.mlAnnotation');
    annotations.each(function (d) {
        // @ts-ignore
        const element = d3_1.default.select(this);
        if (d._id === annotation._id) {
            element.selectAll('.mlAnnotationRect').classed('mlAnnotationRect-isHighlight', true);
        }
        else {
            element.selectAll('.mlAnnotationTextRect').classed('mlAnnotationTextRect-isBlur', true);
            element.selectAll('.mlAnnotationText').classed('mlAnnotationText-isBlur', true);
            element.selectAll('.mlAnnotationRect').classed('mlAnnotationRect-isBlur', true);
        }
    });
}
exports.highlightFocusChartAnnotation = highlightFocusChartAnnotation;
function unhighlightFocusChartAnnotation() {
    const annotations = d3_1.default.selectAll('.mlAnnotation');
    annotations.each(function () {
        // @ts-ignore
        const element = d3_1.default.select(this);
        element.selectAll('.mlAnnotationTextRect').classed('mlAnnotationTextRect-isBlur', false);
        element
            .selectAll('.mlAnnotationRect')
            .classed('mlAnnotationRect-isHighlight', false)
            .classed('mlAnnotationRect-isBlur', false);
        element.selectAll('.mlAnnotationText').classed('mlAnnotationText-isBlur', false);
    });
}
exports.unhighlightFocusChartAnnotation = unhighlightFocusChartAnnotation;
