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
 * This file contains logic for transforming / migrating a saved object document.
 *
 * At first, it may seem as if this could be a simple filter + reduce operation,
 * running the document through a linear set of transform functions until it is
 * up to date, but there are some edge cases that make it more complicated.
 *
 * A transform can add a new property, rename an existing property, remove a property, etc.
 * This means that we aren't able to do a reduce over a fixed list of properties, as
 * each transform operation could essentially change what transforms should be applied
 * next.
 *
 * The basic algorithm, then, is this:
 *
 * While there are any unmigrated properties in the doc, find the next unmigrated property,
 * and run the doc through the transforms that target that property.
 *
 * This way, we keep looping until there are no transforms left to apply, and we properly
 * handle property addition / deletion / renaming.
 *
 * A caveat is that this means we must restrict what a migration can do to the doc's
 * migrationVersion itself. We allow only these kinds of changes:
 *
 * - Add a new property to migrationVersion
 * - Move a migrationVersion property forward to a later version
 *
 * Migrations *cannot* move a migrationVersion property backwards (e.g. from 2.0.0 to 1.0.0), and they
 * cannot clear a migrationVersion property, as allowing either of these could produce infinite loops.
 * However, we do wish to allow migrations to modify migrationVersion if they wish, so that
 * they could transform a type from "foo 1.0.0" to  "bar 3.0.0".
 *
 * One last gotcha is that any docs which have no migrationVersion are assumed to be up-to-date.
 * This is because Kibana UI and other clients really can't be expected build the migrationVersion
 * in a reliable way. Instead, callers of our APIs are expected to send us up-to-date documents,
 * and those documents are simply given a stamp of approval by this transformer. This is why it is
 * important for migration authors to *also* write a saved object validation that will prevent this
 * assumption from inserting out-of-date documents into the index.
 *
 * If the client(s) send us documents with migrationVersion specified, we will migrate them as
 * appropriate. This means for data import scenarios, any documetns being imported should be explicitly
 * given an empty migrationVersion property {} if no such property exists.
 */
const boom_1 = tslib_1.__importDefault(require("boom"));
const lodash_1 = tslib_1.__importDefault(require("lodash"));
const semver_1 = tslib_1.__importDefault(require("semver"));
const migration_logger_1 = require("./migration_logger");
/**
 * A concrete implementation of the VersionedTransformer interface.
 */
class DocumentMigrator {
    /**
     * Creates an instance of DocumentMigrator.
     *
     * @param {Opts} opts
     * @prop {string} kibanaVersion - The current version of Kibana
     * @prop {MigrationDefinition} migrations - The migrations that will be used to migrate documents
     * @prop {ValidateDoc} validateDoc - A function which, given a document throws an error if it is
     *   not up to date. This is used to ensure we don't let unmigrated documents slip through.
     * @prop {Logger} log - The migration logger
     * @memberof DocumentMigrator
     */
    constructor(opts) {
        /**
         * Migrates a document to the latest version.
         *
         * @param {SavedObjectDoc} doc
         * @returns {SavedObjectDoc}
         * @memberof DocumentMigrator
         */
        this.migrate = (doc) => {
            return this.transformDoc(doc);
        };
        validateMigrationDefinition(opts.migrations);
        this.migrations = buildActiveMigrations(opts.migrations, new migration_logger_1.MigrationLogger(opts.log));
        this.transformDoc = buildDocumentTransform({
            kibanaVersion: opts.kibanaVersion,
            migrations: this.migrations,
            validateDoc: opts.validateDoc,
        });
    }
    /**
     * Gets the latest version of each migratable property.
     *
     * @readonly
     * @type {MigrationVersion}
     * @memberof DocumentMigrator
     */
    get migrationVersion() {
        return lodash_1.default.mapValues(this.migrations, ({ latestVersion }) => latestVersion);
    }
}
exports.DocumentMigrator = DocumentMigrator;
/**
 * Basic validation that the migraiton definition matches our expectations. We can't
 * rely on TypeScript here, as the caller may be JavaScript / ClojureScript / any compile-to-js
 * language. So, this is just to provide a little developer-friendly error messaging. Joi was
 * giving weird errors, so we're just doing manual validation.
 */
function validateMigrationDefinition(migrations) {
    function assertObject(obj, prefix) {
        if (!obj || typeof obj !== 'object') {
            throw new Error(`${prefix} Got ${obj}.`);
        }
    }
    function assertValidSemver(version, type) {
        if (!semver_1.default.valid(version)) {
            throw new Error(`Invalid migration for type ${type}. Expected all properties to be semvers, but got ${version}.`);
        }
    }
    function assertValidTransform(fn, version, type) {
        if (typeof fn !== 'function') {
            throw new Error(`Invalid migration ${type}.${version}: expected a function, but got ${fn}.`);
        }
    }
    assertObject(migrations, 'Migration definition should be an object.');
    Object.entries(migrations).forEach(([type, versions]) => {
        assertObject(versions, `Migration for type ${type} should be an object like { '2.0.0': (doc) => doc }.`);
        Object.entries(versions).forEach(([version, fn]) => {
            assertValidSemver(version, type);
            assertValidTransform(fn, version, type);
        });
    });
}
/**
 * Converts migrations from a format that is convenient for callers to a format that
 * is convenient for our internal usage:
 * From: { type: { version: fn } }
 * To:   { type: { latestVersion: string, transforms: [{ version: string, transform: fn }] } }
 */
function buildActiveMigrations(migrations, log) {
    return lodash_1.default.mapValues(migrations, (versions, prop) => {
        const transforms = Object.entries(versions)
            .map(([version, transform]) => ({
            version,
            transform: wrapWithTry(version, prop, transform, log),
        }))
            .sort((a, b) => semver_1.default.compare(a.version, b.version));
        return {
            latestVersion: lodash_1.default.last(transforms).version,
            transforms,
        };
    });
}
/**
 * Creates a function which migrates and validates any document that is passed to it.
 */
function buildDocumentTransform({ kibanaVersion, migrations, validateDoc, }) {
    return function transformAndValidate(doc) {
        const result = doc.migrationVersion
            ? applyMigrations(doc, migrations)
            : markAsUpToDate(doc, migrations);
        validateDoc(result);
        // In order to keep tests a bit more stable, we won't
        // tack on an empy migrationVersion to docs that have
        // no migrations defined.
        if (lodash_1.default.isEmpty(result.migrationVersion)) {
            delete result.migrationVersion;
        }
        return result;
    };
}
function applyMigrations(doc, migrations) {
    while (true) {
        const prop = nextUnmigratedProp(doc, migrations);
        if (!prop) {
            return doc;
        }
        doc = migrateProp(doc, prop, migrations);
    }
}
/**
 * Gets the doc's props, handling the special case of "type".
 */
function props(doc) {
    return Object.keys(doc).concat(doc.type);
}
/**
 * Looks up the prop version in a saved object document or in our latest migrations.
 */
function propVersion(doc, prop) {
    return ((doc[prop] && doc[prop].latestVersion) ||
        (doc.migrationVersion && doc.migrationVersion[prop]));
}
/**
 * Sets the doc's migrationVersion to be the most recent version
 */
function markAsUpToDate(doc, migrations) {
    return {
        ...doc,
        migrationVersion: props(doc).reduce((acc, prop) => {
            const version = propVersion(migrations, prop);
            return version ? lodash_1.default.set(acc, prop, version) : acc;
        }, {}),
    };
}
/**
 * If a specific transform function fails, this tacks on a bit of information
 * about the document and transform that caused the failure.
 */
function wrapWithTry(version, prop, transform, log) {
    return function tryTransformDoc(doc) {
        try {
            const result = transform(doc);
            // A basic sanity check to help migration authors detect basic errors
            // (e.g. forgetting to return the transformed doc)
            if (!result || !result.type) {
                throw new Error(`Invalid saved object returned from migration ${prop}:${version}.`);
            }
            return result;
        }
        catch (error) {
            const failedTransform = `${prop}:${version}`;
            const failedDoc = JSON.stringify(doc);
            log.warning(`Failed to transform document ${doc}. Transform: ${failedTransform}\nDoc: ${failedDoc}`);
            throw error;
        }
    };
}
/**
 * Finds the first unmigrated property in the specified document.
 */
function nextUnmigratedProp(doc, migrations) {
    return props(doc).find(p => {
        const latestVersion = propVersion(migrations, p);
        const docVersion = propVersion(doc, p);
        if (latestVersion === docVersion) {
            return false;
        }
        // We verify that the version is not greater than the version supported by Kibana.
        // If we didn't, this would cause an infinite loop, as we'd be unable to migrate the property
        // but it would continue to show up as unmigrated.
        // If we have a docVersion and the latestVersion is smaller than it or does not exist,
        // we are dealing with a document that belongs to a future Kibana / plugin version.
        if (docVersion && (!latestVersion || semver_1.default.gt(docVersion, latestVersion))) {
            throw boom_1.default.badData(`Document "${doc.id}" has property "${p}" which belongs to a more recent` +
                ` version of Kibana (${docVersion}).`, doc);
        }
        return true;
    });
}
/**
 * Applies any relevent migrations to the document for the specified property.
 */
function migrateProp(doc, prop, migrations) {
    const originalType = doc.type;
    let migrationVersion = lodash_1.default.clone(doc.migrationVersion) || {};
    const typeChanged = () => !doc.hasOwnProperty(prop) || doc.type !== originalType;
    for (const { version, transform } of applicableTransforms(migrations, doc, prop)) {
        doc = transform(doc);
        migrationVersion = updateMigrationVersion(doc, migrationVersion, prop, version);
        doc.migrationVersion = lodash_1.default.clone(migrationVersion);
        if (typeChanged()) {
            break;
        }
    }
    return doc;
}
/**
 * Retrieves any prop transforms that have not been applied to doc.
 */
function applicableTransforms(migrations, doc, prop) {
    const minVersion = propVersion(doc, prop);
    const { transforms } = migrations[prop];
    return minVersion
        ? transforms.filter(({ version }) => semver_1.default.gt(version, minVersion))
        : transforms;
}
/**
 * Updates the document's migrationVersion, ensuring that the calling transform
 * has not mutated migrationVersion in an unsupported way.
 */
function updateMigrationVersion(doc, migrationVersion, prop, version) {
    assertNoDowngrades(doc, migrationVersion, prop, version);
    const docVersion = propVersion(doc, prop) || '0.0.0';
    const maxVersion = semver_1.default.gt(docVersion, version) ? docVersion : version;
    return { ...(doc.migrationVersion || migrationVersion), [prop]: maxVersion };
}
/**
 * Transforms that remove or downgrade migrationVersion properties are not allowed,
 * as this could get us into an infinite loop. So, we explicitly check for that here.
 */
function assertNoDowngrades(doc, migrationVersion, prop, version) {
    const docVersion = doc.migrationVersion;
    if (!docVersion) {
        return;
    }
    const downgrade = Object.keys(migrationVersion).find(k => !docVersion.hasOwnProperty(k) || semver_1.default.lt(docVersion[k], migrationVersion[k]));
    if (downgrade) {
        throw new Error(`Migration "${prop} v ${version}" attempted to ` +
            `downgrade "migrationVersion.${downgrade}" from ${migrationVersion[downgrade]} ` +
            `to ${docVersion[downgrade]}.`);
    }
}
