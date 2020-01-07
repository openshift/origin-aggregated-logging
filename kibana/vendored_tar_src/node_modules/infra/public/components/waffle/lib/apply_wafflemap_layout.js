"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */
const lodash_1 = require("lodash");
const type_guards_1 = require("../../../containers/waffle/type_guards");
const size_of_squares_1 = require("./size_of_squares");
function getColumns(n, w = 1, h = 1) {
    const pageRatio = w / h;
    const ratio = pageRatio > 1.2 ? 1.2 : pageRatio;
    const width = Math.ceil(Math.sqrt(n));
    return Math.ceil(width * ratio);
}
exports.getColumns = getColumns;
function getTotalItems(groups) {
    if (!groups) {
        return 0;
    }
    return groups.reduce((acc, group) => {
        if (type_guards_1.isWaffleMapGroupWithGroups(group)) {
            return group.groups.reduce((total, subGroup) => subGroup.nodes.length + total, acc);
        }
        if (type_guards_1.isWaffleMapGroupWithNodes(group)) {
            return group.nodes.length + acc;
        }
        return acc;
    }, 0);
}
exports.getTotalItems = getTotalItems;
function getLargestCount(groups) {
    if (!groups) {
        return 0;
    }
    return groups.reduce((total, group) => {
        if (type_guards_1.isWaffleMapGroupWithGroups(group)) {
            return group.groups.reduce((subTotal, subGroup) => {
                if (type_guards_1.isWaffleMapGroupWithNodes(subGroup)) {
                    return subTotal > subGroup.nodes.length ? subTotal : subGroup.nodes.length;
                }
                return subTotal;
            }, total);
        }
        if (type_guards_1.isWaffleMapGroupWithNodes(group)) {
            return total > group.nodes.length ? total : group.nodes.length;
        }
        return total;
    }, 0);
}
exports.getLargestCount = getLargestCount;
const getTotalItemsOfGroup = (group) => getTotalItems([group]);
function applyWaffleMapLayout(groups, width, height) {
    if (groups.length === 0) {
        return [];
    }
    const levels = type_guards_1.isWaffleMapGroupWithGroups(lodash_1.first(groups)) ? 2 : 1;
    const totalItems = getTotalItems(groups);
    const squareSize = Math.round(size_of_squares_1.sizeOfSquares(width, height, totalItems, levels));
    const largestCount = getLargestCount(groups);
    return lodash_1.sortBy(groups, getTotalItemsOfGroup)
        .reverse()
        .map(group => {
        if (type_guards_1.isWaffleMapGroupWithGroups(group)) {
            const columns = getColumns(largestCount, width, height);
            const groupOfNodes = group.groups;
            const subGroups = lodash_1.sortBy(groupOfNodes, getTotalItemsOfGroup)
                .reverse()
                .filter(type_guards_1.isWaffleMapGroupWithNodes)
                .map(subGroup => {
                return {
                    ...subGroup,
                    count: subGroup.nodes.length,
                    columns,
                    width: columns * squareSize,
                    squareSize,
                };
            });
            return {
                ...group,
                groups: subGroups,
                count: getTotalItems([group]),
                squareSize,
            };
        }
        if (type_guards_1.isWaffleMapGroupWithNodes(group)) {
            const columns = getColumns(Math.max(group.nodes.length, largestCount), width, height);
            return {
                ...group,
                count: group.nodes.length,
                squareSize,
                width: columns * squareSize,
            };
        }
        return group;
    });
}
exports.applyWaffleMapLayout = applyWaffleMapLayout;
