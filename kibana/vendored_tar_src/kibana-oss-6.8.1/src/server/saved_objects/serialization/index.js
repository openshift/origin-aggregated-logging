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
const tslib_1 = require("tslib");
/*
 * This file contains the logic for transforming saved objects to / from
 * the raw document format as stored in ElasticSearch.
 */
const uuid_1 = tslib_1.__importDefault(require("uuid"));
const version_1 = require("../version");
/**
 * The root document type. In 7.0, this needs to change to '_doc'.
 */
exports.ROOT_TYPE = 'doc';
function assertNonEmptyString(value, name) {
    if (!value || typeof value !== 'string') {
        throw new TypeError(`Expected "${value}" to be a ${name}`);
    }
}
class SavedObjectsSerializer {
    constructor(schema) {
        this.schema = schema;
    }
    /**
     * Determines whether or not the raw document can be converted to a saved object.
     *
     * @param {RawDoc} rawDoc - The raw ES document to be tested
     */
    isRawSavedObject(rawDoc) {
        const { type, namespace } = rawDoc._source;
        const namespacePrefix = namespace && !this.schema.isNamespaceAgnostic(type) ? `${namespace}:` : '';
        return (type &&
            rawDoc._id.startsWith(`${namespacePrefix}${type}:`) &&
            rawDoc._source.hasOwnProperty(type));
    }
    /**
     * Converts a document from the format that is stored in elasticsearch to the saved object client format.
     *
     *  @param {RawDoc} rawDoc - The raw ES document to be converted to saved object format.
     */
    rawToSavedObject({ _id, _source, _seq_no, _primary_term }) {
        const { type, namespace } = _source;
        const version = _seq_no != null || _primary_term != null
            ? version_1.encodeVersion(_seq_no, _primary_term)
            : undefined;
        return {
            type,
            id: this.trimIdPrefix(namespace, type, _id),
            ...(namespace && !this.schema.isNamespaceAgnostic(type) && { namespace }),
            attributes: _source[type],
            ...(_source.migrationVersion && { migrationVersion: _source.migrationVersion }),
            ...(_source.updated_at && { updated_at: _source.updated_at }),
            ...(version && { version }),
        };
    }
    /**
     * Converts a document from the saved object client format to the format that is stored in elasticsearch.
     *
     * @param {SavedObjectDoc} savedObj - The saved object to be converted to raw ES format.
     */
    savedObjectToRaw(savedObj) {
        const { id, type, namespace, attributes, migrationVersion, updated_at, version } = savedObj;
        const source = {
            [type]: attributes,
            type,
            ...(namespace && !this.schema.isNamespaceAgnostic(type) && { namespace }),
            ...(migrationVersion && { migrationVersion }),
            ...(updated_at && { updated_at }),
        };
        return {
            _id: this.generateRawId(namespace, type, id),
            _source: source,
            _type: exports.ROOT_TYPE,
            ...(version != null && version_1.decodeVersion(version)),
        };
    }
    /**
     * Given a saved object type and id, generates the compound id that is stored in the raw document.
     *
     * @param {string} namespace - The namespace of the saved object
     * @param {string} type - The saved object type
     * @param {string} id - The id of the saved object
     */
    generateRawId(namespace, type, id) {
        const namespacePrefix = namespace && !this.schema.isNamespaceAgnostic(type) ? `${namespace}:` : '';
        return `${namespacePrefix}${type}:${id || uuid_1.default.v1()}`;
    }
    trimIdPrefix(namespace, type, id) {
        assertNonEmptyString(id, 'document id');
        assertNonEmptyString(type, 'saved object type');
        const namespacePrefix = namespace && !this.schema.isNamespaceAgnostic(type) ? `${namespace}:` : '';
        const prefix = `${namespacePrefix}${type}:`;
        if (!id.startsWith(prefix)) {
            return id;
        }
        return id.slice(prefix.length);
    }
}
exports.SavedObjectsSerializer = SavedObjectsSerializer;
