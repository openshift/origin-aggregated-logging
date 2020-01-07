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
import * as tslib_1 from "tslib";
import { MetadataActionTypeKeys, } from '../actions';
var updateTitle = function (metadata, title) { return (tslib_1.__assign({}, metadata, { title: title })); };
var updateDescription = function (metadata, description) { return (tslib_1.__assign({}, metadata, { description: description })); };
export var metadataReducer = function (metadata, action) {
    if (metadata === void 0) { metadata = {
        description: '',
        title: '',
    }; }
    switch (action.type) {
        case MetadataActionTypeKeys.UPDATE_TITLE:
            return updateTitle(metadata, action.payload);
        case MetadataActionTypeKeys.UPDATE_DESCRIPTION:
            return updateDescription(metadata, action.payload);
        default:
            return metadata;
    }
};
