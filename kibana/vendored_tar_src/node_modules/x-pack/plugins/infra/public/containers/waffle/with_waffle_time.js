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
const reselect_1 = require("reselect");
const store_1 = require("../../store");
const typed_react_1 = require("../../utils/typed_react");
const typed_redux_1 = require("../../utils/typed_redux");
const url_state_1 = require("../../utils/url_state");
exports.withWaffleTime = react_redux_1.connect((state) => ({
    currentTime: store_1.waffleTimeSelectors.selectCurrentTime(state),
    currentTimeRange: store_1.waffleTimeSelectors.selectCurrentTimeRange(state),
    isAutoReloading: store_1.waffleTimeSelectors.selectIsAutoReloading(state),
    urlState: selectTimeUrlState(state),
}), typed_redux_1.bindPlainActionCreators({
    jumpToTime: store_1.waffleTimeActions.jumpToTime,
    startAutoReload: store_1.waffleTimeActions.startAutoReload,
    stopAutoReload: store_1.waffleTimeActions.stopAutoReload,
}));
exports.WithWaffleTime = typed_react_1.asChildFunctionRenderer(exports.withWaffleTime, {
    onCleanup: ({ stopAutoReload }) => stopAutoReload(),
});
exports.WithWaffleTimeUrlState = () => (react_1.default.createElement(exports.WithWaffleTime, null, ({ jumpToTime, startAutoReload, stopAutoReload, urlState }) => (react_1.default.createElement(url_state_1.UrlStateContainer, { urlState: urlState, urlStateKey: "waffleTime", mapToUrlState: mapToUrlState, onChange: newUrlState => {
        if (newUrlState && newUrlState.time) {
            jumpToTime(newUrlState.time);
        }
        if (newUrlState && newUrlState.autoReload) {
            startAutoReload();
        }
        else if (newUrlState &&
            typeof newUrlState.autoReload !== 'undefined' &&
            !newUrlState.autoReload) {
            stopAutoReload();
        }
    }, onInitialize: initialUrlState => {
        if (initialUrlState) {
            jumpToTime(initialUrlState.time ? initialUrlState.time : Date.now());
        }
        if (initialUrlState && initialUrlState.autoReload) {
            startAutoReload();
        }
    } }))));
const selectTimeUrlState = reselect_1.createSelector(store_1.waffleTimeSelectors.selectCurrentTime, store_1.waffleTimeSelectors.selectIsAutoReloading, (time, autoReload) => ({
    time,
    autoReload,
}));
const mapToUrlState = (value) => value
    ? {
        time: mapToTimeUrlState(value.time),
        autoReload: mapToAutoReloadUrlState(value.autoReload),
    }
    : undefined;
const mapToTimeUrlState = (value) => (value && typeof value === 'number' ? value : undefined);
const mapToAutoReloadUrlState = (value) => (typeof value === 'boolean' ? value : undefined);
