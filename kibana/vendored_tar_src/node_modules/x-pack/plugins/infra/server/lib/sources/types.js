"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const runtimeTypes = tslib_1.__importStar(require("io-ts"));
const moment_1 = tslib_1.__importDefault(require("moment"));
exports.TimestampFromString = new runtimeTypes.Type('TimestampFromString', (input) => typeof input === 'number', (input, context) => runtimeTypes.string.validate(input, context).chain(stringInput => {
    const momentValue = moment_1.default(stringInput);
    return momentValue.isValid()
        ? runtimeTypes.success(momentValue.valueOf())
        : runtimeTypes.failure(stringInput, context);
}), output => new Date(output).toISOString());
/**
 * Stored source configuration as read from and written to saved objects
 */
const SavedSourceConfigurationFieldsRuntimeType = runtimeTypes.partial({
    container: runtimeTypes.string,
    host: runtimeTypes.string,
    pod: runtimeTypes.string,
    tiebreaker: runtimeTypes.string,
    timestamp: runtimeTypes.string,
});
exports.SavedSourceConfigurationRuntimeType = runtimeTypes.partial({
    name: runtimeTypes.string,
    description: runtimeTypes.string,
    metricAlias: runtimeTypes.string,
    logAlias: runtimeTypes.string,
    fields: SavedSourceConfigurationFieldsRuntimeType,
});
exports.pickSavedSourceConfiguration = (value) => {
    const { container, host, pod, tiebreaker, timestamp } = value.fields;
    return {
        ...value,
        fields: { container, host, pod, tiebreaker, timestamp },
    };
};
/**
 * Static source configuration as read from the configuration file
 */
const StaticSourceConfigurationFieldsRuntimeType = runtimeTypes.partial({
    ...SavedSourceConfigurationFieldsRuntimeType.props,
    message: runtimeTypes.array(runtimeTypes.string),
});
exports.StaticSourceConfigurationRuntimeType = runtimeTypes.partial({
    name: runtimeTypes.string,
    description: runtimeTypes.string,
    metricAlias: runtimeTypes.string,
    logAlias: runtimeTypes.string,
    fields: StaticSourceConfigurationFieldsRuntimeType,
});
/**
 * Full source configuration type after all cleanup has been done at the edges
 */
const SourceConfigurationFieldsRuntimeType = runtimeTypes.type({
    ...StaticSourceConfigurationFieldsRuntimeType.props,
});
exports.SourceConfigurationRuntimeType = runtimeTypes.type({
    ...exports.SavedSourceConfigurationRuntimeType.props,
    fields: SourceConfigurationFieldsRuntimeType,
});
/**
 * Saved object type with metadata
 */
exports.SourceConfigurationSavedObjectRuntimeType = runtimeTypes.intersection([
    runtimeTypes.type({
        id: runtimeTypes.string,
        attributes: exports.SavedSourceConfigurationRuntimeType,
    }),
    runtimeTypes.partial({
        version: runtimeTypes.string,
        updated_at: exports.TimestampFromString,
    }),
]);
