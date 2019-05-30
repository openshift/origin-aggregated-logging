"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const callApi_1 = require("../callApi");
const apm_1 = require("./apm");
async function loadErrorGroupList({ serviceName, start, end, kuery, size, sortField, sortDirection }) {
    return callApi_1.callApi({
        pathname: `/api/apm/services/${serviceName}/errors`,
        query: {
            start,
            end,
            size,
            sortField,
            sortDirection,
            esFilterQuery: await apm_1.getEncodedEsQuery(kuery)
        }
    });
}
exports.loadErrorGroupList = loadErrorGroupList;
async function loadErrorGroupDetails({ serviceName, start, end, kuery, errorGroupId }) {
    return callApi_1.callApi({
        pathname: `/api/apm/services/${serviceName}/errors/${errorGroupId}`,
        query: {
            start,
            end,
            esFilterQuery: await apm_1.getEncodedEsQuery(kuery)
        }
    });
}
exports.loadErrorGroupDetails = loadErrorGroupDetails;
async function loadErrorDistribution({ serviceName, start, end, kuery, errorGroupId }) {
    const pathname = errorGroupId
        ? `/api/apm/services/${serviceName}/errors/${errorGroupId}/distribution`
        : `/api/apm/services/${serviceName}/errors/distribution`;
    return callApi_1.callApi({
        pathname,
        query: {
            start,
            end,
            esFilterQuery: await apm_1.getEncodedEsQuery(kuery)
        }
    });
}
exports.loadErrorDistribution = loadErrorDistribution;
