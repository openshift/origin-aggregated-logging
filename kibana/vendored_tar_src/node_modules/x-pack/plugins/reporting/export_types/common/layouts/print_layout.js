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
class PrintLayout extends layout_1.Layout {
    constructor(server) {
        super(constants_1.LayoutTypes.PRINT);
        this.selectors = {
            screenshot: '[data-shared-item]',
            renderComplete: '[data-shared-item]',
            itemsCountAttribute: 'data-shared-items-count',
            timefilterFromAttribute: 'data-shared-timefilter-from',
            timefilterToAttribute: 'data-shared-timefilter-to',
            toastHeader: '[data-test-subj="euiToastHeader"]',
        };
        this.groupCount = 2;
        this.captureConfig = server.config().get('xpack.reporting.capture');
    }
    getCssOverridesPath() {
        return path_1.default.join(__dirname, 'print.css');
    }
    getBrowserViewport() {
        return this.captureConfig.viewport;
    }
    getBrowserZoom() {
        return this.captureConfig.zoom;
    }
    getViewport(itemsCount) {
        return {
            zoom: this.captureConfig.zoom,
            width: this.captureConfig.viewport.width,
            height: this.captureConfig.viewport.height * itemsCount,
        };
    }
    async positionElements(browser) {
        const elementSize = {
            width: this.captureConfig.viewport.width / this.captureConfig.zoom,
            height: this.captureConfig.viewport.height / this.captureConfig.zoom,
        };
        const evalOptions = {
            fn: (selector, height, width) => {
                const visualizations = document.querySelectorAll(selector);
                const visualizationsLength = visualizations.length;
                for (let i = 0; i < visualizationsLength; i++) {
                    const visualization = visualizations[i];
                    const style = visualization.style;
                    style.position = 'fixed';
                    style.top = `${height * i}px`;
                    style.left = '0';
                    style.width = `${width}px`;
                    style.height = `${height}px`;
                    style.zIndex = '1';
                    style.backgroundColor = 'inherit';
                }
            },
            args: [this.selectors.screenshot, elementSize.height, elementSize.width],
        };
        await browser.evaluate(evalOptions);
    }
    getPdfImageSize() {
        return {
            width: 500,
        };
    }
    getPdfPageOrientation() {
        return 'portrait';
    }
    getPdfPageSize() {
        return 'A4';
    }
}
exports.PrintLayout = PrintLayout;
