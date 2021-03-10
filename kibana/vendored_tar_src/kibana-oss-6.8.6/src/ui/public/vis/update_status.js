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
import { calculateObjectHash } from './lib/calculate_object_hash';
var Status;
(function (Status) {
    Status["AGGS"] = "aggs";
    Status["DATA"] = "data";
    Status["PARAMS"] = "params";
    Status["RESIZE"] = "resize";
    Status["TIME"] = "time";
    Status["UI_STATE"] = "uiState";
})(Status || (Status = {}));
/**
 * Checks whether the hash of a specific key in the given oldStatus has changed
 * compared to the new valueHash passed.
 */
function hasHashChanged(valueHash, oldStatus, name) {
    var oldHash = oldStatus[name];
    return oldHash !== valueHash;
}
function hasSizeChanged(size, oldSize) {
    if (!oldSize) {
        return true;
    }
    return oldSize.width !== size.width || oldSize.height !== size.height;
}
function getUpdateStatus(requiresUpdateStatus, obj, param) {
    if (requiresUpdateStatus === void 0) { requiresUpdateStatus = []; }
    var e_1, _a;
    var status = {};
    // If the vis type doesn't need update status, skip all calculations
    if (requiresUpdateStatus.length === 0) {
        return status;
    }
    if (!obj._oldStatus) {
        obj._oldStatus = {};
    }
    try {
        for (var requiresUpdateStatus_1 = tslib_1.__values(requiresUpdateStatus), requiresUpdateStatus_1_1 = requiresUpdateStatus_1.next(); !requiresUpdateStatus_1_1.done; requiresUpdateStatus_1_1 = requiresUpdateStatus_1.next()) {
            var requiredStatus = requiresUpdateStatus_1_1.value;
            var hash = void 0;
            // Calculate all required status updates for this visualization
            switch (requiredStatus) {
                case Status.AGGS:
                    hash = calculateObjectHash(param.vis.aggs);
                    status.aggs = hasHashChanged(hash, obj._oldStatus, 'aggs');
                    obj._oldStatus.aggs = hash;
                    break;
                case Status.DATA:
                    hash = calculateObjectHash(param.visData);
                    status.data = hasHashChanged(hash, obj._oldStatus, 'data');
                    obj._oldStatus.data = hash;
                    break;
                case Status.PARAMS:
                    hash = calculateObjectHash(param.vis.params);
                    status.params = hasHashChanged(hash, obj._oldStatus, 'param');
                    obj._oldStatus.param = hash;
                    break;
                case Status.RESIZE:
                    var width = param.vis.size ? param.vis.size[0] : 0;
                    var height = param.vis.size ? param.vis.size[1] : 0;
                    var size = { width: width, height: height };
                    status.resize = hasSizeChanged(size, obj._oldStatus.resize);
                    obj._oldStatus.resize = size;
                    break;
                case Status.TIME:
                    var timeRange = param.vis.filters && param.vis.filters.timeRange;
                    hash = calculateObjectHash(timeRange);
                    status.time = hasHashChanged(hash, obj._oldStatus, 'time');
                    obj._oldStatus.time = hash;
                    break;
                case Status.UI_STATE:
                    hash = calculateObjectHash(param.uiState);
                    status.uiState = hasHashChanged(hash, obj._oldStatus, 'uiState');
                    obj._oldStatus.uiState = hash;
                    break;
            }
        }
    }
    catch (e_1_1) { e_1 = { error: e_1_1 }; }
    finally {
        try {
            if (requiresUpdateStatus_1_1 && !requiresUpdateStatus_1_1.done && (_a = requiresUpdateStatus_1.return)) _a.call(requiresUpdateStatus_1);
        }
        finally { if (e_1) throw e_1.error; }
    }
    return status;
}
export { getUpdateStatus, Status };
