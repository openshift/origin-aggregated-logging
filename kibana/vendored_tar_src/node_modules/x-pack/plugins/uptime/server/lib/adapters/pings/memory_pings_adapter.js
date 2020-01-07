"use strict";
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const lodash_1 = require("lodash");
const sortPings = (sort) => sort === 'asc'
    ? (a, b) => (Date.parse(a.timestamp) > Date.parse(b.timestamp) ? 1 : 0)
    : (a, b) => (Date.parse(a.timestamp) > Date.parse(b.timestamp) ? 0 : 1);
class MemoryPingsAdapter {
    constructor(pingsDB) {
        this.pingsDB = pingsDB;
    }
    async getAll(request, dateRangeStart, dateRangeEnd, monitorId, status, sort, size) {
        let pings = this.pingsDB;
        if (monitorId) {
            pings = pings.filter(ping => ping.monitor && ping.monitor.id === monitorId);
        }
        size = size ? size : 10;
        return {
            total: size,
            pings: lodash_1.take(sort ? pings.sort(sortPings(sort)) : pings, size),
        };
    }
    // TODO: implement
    getLatestMonitorDocs(request, dateRangeStart, dateRangeEnd, monitorId) {
        throw new Error('Method not implemented.');
    }
    // TODO: implement
    getPingHistogram(request, dateRangeStart, dateRangeEnd, filters) {
        throw new Error('Method not implemented.');
    }
    // TODO: implement
    getDocCount(request) {
        throw new Error('Method not implemented.');
    }
}
exports.MemoryPingsAdapter = MemoryPingsAdapter;
