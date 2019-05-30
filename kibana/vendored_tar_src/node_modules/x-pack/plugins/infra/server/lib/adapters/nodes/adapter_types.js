"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
var InfraNodesKey;
(function (InfraNodesKey) {
    InfraNodesKey["hosts"] = "hosts";
    InfraNodesKey["pods"] = "pods";
    InfraNodesKey["containers"] = "containers";
})(InfraNodesKey = exports.InfraNodesKey || (exports.InfraNodesKey = {}));
var InfraNodeType;
(function (InfraNodeType) {
    InfraNodeType["host"] = "host";
    InfraNodeType["pod"] = "pod";
    InfraNodeType["container"] = "container";
})(InfraNodeType = exports.InfraNodeType || (exports.InfraNodeType = {}));
