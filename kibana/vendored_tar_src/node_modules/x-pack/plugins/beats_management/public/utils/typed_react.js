"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const lodash_1 = require("lodash");
const react_1 = tslib_1.__importDefault(require("react"));
exports.asChildFunctionRenderer = (hoc, { onInitialize, onCleanup } = {}) => hoc(class ChildFunctionRenderer extends react_1.default.Component {
    constructor() {
        super(...arguments);
        this.displayName = 'ChildFunctionRenderer';
        this.getRendererArgs = () => lodash_1.omit(['children', 'initializeOnMount', 'resetOnUnmount'], this.props);
    }
    componentDidMount() {
        if (this.props.initializeOnMount && onInitialize) {
            onInitialize(this.getRendererArgs());
        }
    }
    componentWillUnmount() {
        if (this.props.resetOnUnmount && onCleanup) {
            onCleanup(this.getRendererArgs());
        }
    }
    render() {
        return this.props.children(this.getRendererArgs());
    }
});
function composeStateUpdaters(...updaters) {
    return (state, props) => updaters.reduce((currentState, updater) => updater(currentState, props) || currentState, state);
}
exports.composeStateUpdaters = composeStateUpdaters;
