"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const isEqual_1 = tslib_1.__importDefault(require("lodash/fp/isEqual"));
const react_1 = tslib_1.__importDefault(require("react"));
const resize_observer_polyfill_1 = tslib_1.__importDefault(require("resize-observer-polyfill"));
class AutoSizer extends react_1.default.PureComponent {
    constructor(props) {
        super(props);
        this.element = null;
        this.resizeObserver = null;
        this.windowWidth = -1;
        this.state = {
            boundsMeasurement: {
                height: void 0,
                width: void 0,
            },
            contentMeasurement: {
                height: void 0,
                width: void 0,
            },
        };
        this.measure = (entry) => {
            if (!this.element) {
                return;
            }
            const { content = true, bounds = false } = this.props;
            const { boundsMeasurement: previousBoundsMeasurement, contentMeasurement: previousContentMeasurement, } = this.state;
            const boundsRect = bounds ? this.element.getBoundingClientRect() : null;
            const boundsMeasurement = boundsRect
                ? {
                    height: this.element.getBoundingClientRect().height,
                    width: this.element.getBoundingClientRect().width,
                }
                : previousBoundsMeasurement;
            if (this.props.detectAnyWindowResize &&
                boundsMeasurement &&
                boundsMeasurement.width &&
                this.windowWidth !== -1 &&
                this.windowWidth > window.innerWidth) {
                const gap = this.windowWidth - window.innerWidth;
                boundsMeasurement.width = boundsMeasurement.width - gap;
            }
            this.windowWidth = window.innerWidth;
            const contentRect = content && entry ? entry.contentRect : null;
            const contentMeasurement = contentRect && entry
                ? {
                    height: entry.contentRect.height,
                    width: entry.contentRect.width,
                }
                : previousContentMeasurement;
            if (isEqual_1.default(boundsMeasurement, previousBoundsMeasurement) &&
                isEqual_1.default(contentMeasurement, previousContentMeasurement)) {
                return;
            }
            requestAnimationFrame(() => {
                if (!this.resizeObserver) {
                    return;
                }
                this.setState({ boundsMeasurement, contentMeasurement });
                if (this.props.onResize) {
                    this.props.onResize({
                        bounds: boundsMeasurement,
                        content: contentMeasurement,
                    });
                }
            });
        };
        this.updateMeasurement = () => {
            window.setTimeout(() => {
                this.measure(null);
            }, 0);
        };
        this.storeRef = (element) => {
            if (this.element && this.resizeObserver) {
                this.resizeObserver.unobserve(this.element);
            }
            if (element && this.resizeObserver) {
                this.resizeObserver.observe(element);
            }
            this.element = element;
        };
        if (this.props.detectAnyWindowResize) {
            window.addEventListener('resize', this.updateMeasurement);
        }
        this.resizeObserver = new resize_observer_polyfill_1.default(entries => {
            entries.forEach(entry => {
                if (entry.target === this.element) {
                    this.measure(entry);
                }
            });
        });
    }
    componentWillUnmount() {
        if (this.resizeObserver) {
            this.resizeObserver.disconnect();
            this.resizeObserver = null;
        }
        if (this.props.detectAnyWindowResize) {
            window.removeEventListener('resize', this.updateMeasurement);
        }
    }
    render() {
        const { children } = this.props;
        const { boundsMeasurement, contentMeasurement } = this.state;
        return children({
            bounds: boundsMeasurement,
            content: contentMeasurement,
            measureRef: this.storeRef,
        });
    }
}
exports.AutoSizer = AutoSizer;
