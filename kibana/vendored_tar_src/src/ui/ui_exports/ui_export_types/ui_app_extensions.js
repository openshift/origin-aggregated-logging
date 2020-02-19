'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.aliases = exports.visTypeEnhancers = exports.visualize = exports.shareContextMenuExtensions = exports.search = exports.inspectorViews = exports.canvas = exports.home = exports.hacks = exports.docViews = exports.devTools = exports.indexManagement = exports.managementSections = exports.navbarExtensions = exports.chromeNavControls = exports.fieldFormatEditors = exports.fieldFormats = exports.contextMenuActions = exports.embeddableFactories = exports.savedObjectTypes = exports.autocompleteProviders = exports.visEditorTypes = exports.visRequestHandlers = exports.visResponseHandlers = exports.visTypes = undefined;

var _reduce = require('./reduce');

var _modify_reduce = require('./modify_reduce');

/**
 *  Reducer "preset" that merges named "first-class" appExtensions by
 *  converting them into objects and then concatenating the values of those objects
 *  @type {Function}
 */
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

const appExtension = (0, _modify_reduce.wrap)((0, _modify_reduce.mapSpec)((spec, type) => ({ [type]: spec })), (0, _modify_reduce.alias)('appExtensions'), _reduce.flatConcatValuesAtType);

// plain extension groups produce lists of modules that will be required by the entry
// files to include extensions of specific types into specific apps
const visTypes = exports.visTypes = appExtension;
const visResponseHandlers = exports.visResponseHandlers = appExtension;
const visRequestHandlers = exports.visRequestHandlers = appExtension;
const visEditorTypes = exports.visEditorTypes = appExtension;
const autocompleteProviders = exports.autocompleteProviders = appExtension;
const savedObjectTypes = exports.savedObjectTypes = appExtension;
const embeddableFactories = exports.embeddableFactories = appExtension;
const contextMenuActions = exports.contextMenuActions = appExtension;
const fieldFormats = exports.fieldFormats = appExtension;
const fieldFormatEditors = exports.fieldFormatEditors = appExtension;
const chromeNavControls = exports.chromeNavControls = appExtension;
const navbarExtensions = exports.navbarExtensions = appExtension;
const managementSections = exports.managementSections = appExtension;
const indexManagement = exports.indexManagement = appExtension;
const devTools = exports.devTools = appExtension;
const docViews = exports.docViews = appExtension;
const hacks = exports.hacks = appExtension;
const home = exports.home = appExtension;
const canvas = exports.canvas = appExtension;
const inspectorViews = exports.inspectorViews = appExtension;
const search = exports.search = appExtension;
const shareContextMenuExtensions = exports.shareContextMenuExtensions = appExtension;
// Add a visualize app extension that should be used for visualize specific stuff
const visualize = exports.visualize = appExtension;

// aliases visTypeEnhancers to the visTypes group
const visTypeEnhancers = exports.visTypeEnhancers = (0, _modify_reduce.wrap)((0, _modify_reduce.alias)('visTypes'), appExtension);

// adhoc extension groups can define new extension groups on the fly
// so that plugins could concat their own
const aliases = exports.aliases = _reduce.flatConcatValuesAtType;