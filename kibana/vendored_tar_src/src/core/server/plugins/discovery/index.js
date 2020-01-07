"use strict";
/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
/** @internal */
var plugin_discovery_error_1 = require("./plugin_discovery_error");
exports.PluginDiscoveryError = plugin_discovery_error_1.PluginDiscoveryError;
exports.PluginDiscoveryErrorType = plugin_discovery_error_1.PluginDiscoveryErrorType;
/** @internal */
var plugin_manifest_parser_1 = require("./plugin_manifest_parser");
exports.isNewPlatformPlugin = plugin_manifest_parser_1.isNewPlatformPlugin;
/** @internal */
var plugins_discovery_1 = require("./plugins_discovery");
exports.discover = plugins_discovery_1.discover;
