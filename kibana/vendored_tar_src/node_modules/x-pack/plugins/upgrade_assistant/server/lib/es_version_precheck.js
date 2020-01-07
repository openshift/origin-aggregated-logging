"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const tslib_1 = require("tslib");
const boom_1 = tslib_1.__importDefault(require("boom"));
const lodash_1 = require("lodash");
const semver_1 = require("semver");
const version_1 = require("../../common/version");
/**
 * Returns an array of all the unique Elasticsearch Node Versions in the Elasticsearch cluster.
 * @param request
 */
exports.getAllNodeVersions = async (callCluster) => {
    // Get the version information for all nodes in the cluster.
    const { nodes } = (await callCluster('nodes.info', {
        filterPath: 'nodes.*.version',
    }));
    const versionStrings = Object.values(nodes).map(({ version }) => version);
    return lodash_1.uniq(versionStrings)
        .sort()
        .map(version => new semver_1.SemVer(version));
};
exports.verifyAllMatchKibanaVersion = (allNodeVersions) => {
    // Determine if all nodes in the cluster are running the same major version as Kibana.
    const numDifferentVersion = allNodeVersions.filter(esNodeVersion => esNodeVersion.major !== version_1.CURRENT_VERSION.major).length;
    const numSameVersion = allNodeVersions.filter(esNodeVersion => esNodeVersion.major === version_1.CURRENT_VERSION.major).length;
    if (numDifferentVersion) {
        const error = new boom_1.default(`There are some nodes running a different version of Elasticsearch`, {
            // 426 means "Upgrade Required" and is used when semver compatibility is not met.
            statusCode: 426,
        });
        error.output.payload.attributes = { allNodesUpgraded: !numSameVersion };
        throw error;
    }
};
exports.EsVersionPrecheck = {
    assign: 'esVersionCheck',
    async method(request) {
        const { callWithRequest } = request.server.plugins.elasticsearch.getCluster('admin');
        const callCluster = callWithRequest.bind(callWithRequest, request);
        let allNodeVersions;
        try {
            allNodeVersions = await exports.getAllNodeVersions(callCluster);
        }
        catch (e) {
            if (e.status === 403) {
                throw boom_1.default.forbidden(e.message);
            }
            throw e;
        }
        // This will throw if there is an issue
        exports.verifyAllMatchKibanaVersion(allNodeVersions);
        return true;
    },
};
