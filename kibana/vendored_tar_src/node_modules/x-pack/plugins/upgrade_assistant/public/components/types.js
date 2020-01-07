"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const react_1 = tslib_1.__importDefault(require("react"));
class UpgradeAssistantTabComponent extends react_1.default.Component {
}
exports.UpgradeAssistantTabComponent = UpgradeAssistantTabComponent;
var LoadingState;
(function (LoadingState) {
    LoadingState[LoadingState["Loading"] = 0] = "Loading";
    LoadingState[LoadingState["Success"] = 1] = "Success";
    LoadingState[LoadingState["Error"] = 2] = "Error";
})(LoadingState = exports.LoadingState || (exports.LoadingState = {}));
var LevelFilterOption;
(function (LevelFilterOption) {
    LevelFilterOption["all"] = "all";
    LevelFilterOption["critical"] = "critical";
})(LevelFilterOption = exports.LevelFilterOption || (exports.LevelFilterOption = {}));
var GroupByOption;
(function (GroupByOption) {
    GroupByOption["message"] = "message";
    GroupByOption["index"] = "index";
    GroupByOption["node"] = "node";
})(GroupByOption = exports.GroupByOption || (exports.GroupByOption = {}));
var TelemetryState;
(function (TelemetryState) {
    TelemetryState[TelemetryState["Running"] = 0] = "Running";
    TelemetryState[TelemetryState["Complete"] = 1] = "Complete";
})(TelemetryState = exports.TelemetryState || (exports.TelemetryState = {}));
