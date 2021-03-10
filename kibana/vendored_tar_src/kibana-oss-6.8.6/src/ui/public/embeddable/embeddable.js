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
var Embeddable = /** @class */ (function () {
    // TODO: Make title and editUrl required and move out of options parameter.
    function Embeddable(metadata) {
        if (metadata === void 0) { metadata = {}; }
        this.metadata = {};
        this.metadata = metadata || {};
    }
    Embeddable.prototype.onContainerStateChanged = function (containerState) {
        return;
    };
    /**
     * An embeddable can return inspector adapters if it want the inspector to be
     * available via the context menu of that panel.
     * @return Inspector adapters that will be used to open an inspector for.
     */
    Embeddable.prototype.getInspectorAdapters = function () {
        return undefined;
    };
    Embeddable.prototype.destroy = function () {
        return;
    };
    Embeddable.prototype.reload = function () {
        return;
    };
    return Embeddable;
}());
export { Embeddable };
