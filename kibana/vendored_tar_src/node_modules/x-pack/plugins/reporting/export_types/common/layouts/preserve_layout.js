"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
const path_1 = tslib_1.__importDefault(require("path"));
const constants_1 = require("../constants");
const layout_1 = require("./layout");
// We use a zoom of two to bump up the resolution of the screenshot a bit.
const ZOOM = 2;
class PreserveLayout extends layout_1.Layout {
    constructor(size) {
        super(constants_1.LayoutTypes.PRESERVE_LAYOUT);
        this.selectors = {
            screenshot: '[data-shared-items-container]',
            renderComplete: '[data-shared-item]',
            itemsCountAttribute: 'data-shared-items-count',
            timefilterFromAttribute: 'data-shared-timefilter-from',
            timefilterToAttribute: 'data-shared-timefilter-to',
            toastHeader: '[data-test-subj="euiToastHeader"]',
        };
        this.groupCount = 1;
        this.height = size.height;
        this.width = size.width;
        this.scaledHeight = size.height * ZOOM;
        this.scaledWidth = size.width * ZOOM;
    }
    getCssOverridesPath() {
        return path_1.default.join(__dirname, 'preserve_layout.css');
    }
    getBrowserViewport() {
        return {
            height: this.scaledHeight,
            width: this.scaledWidth,
        };
    }
    getBrowserZoom() {
        return ZOOM;
    }
    getViewport() {
        return {
            height: this.scaledHeight,
            width: this.scaledWidth,
            zoom: ZOOM,
        };
    }
    getPdfImageSize() {
        return {
            height: this.height,
            width: this.width,
        };
    }
    getPdfPageOrientation() {
        return undefined;
    }
    getPdfPageSize(pageSizeParams) {
        return {
            height: this.height +
                pageSizeParams.pageMarginTop +
                pageSizeParams.pageMarginBottom +
                pageSizeParams.tableBorderWidth * 2 +
                pageSizeParams.headingHeight +
                pageSizeParams.subheadingHeight,
            width: this.width + pageSizeParams.pageMarginWidth * 2 + pageSizeParams.tableBorderWidth * 2,
        };
    }
}
exports.PreserveLayout = PreserveLayout;
