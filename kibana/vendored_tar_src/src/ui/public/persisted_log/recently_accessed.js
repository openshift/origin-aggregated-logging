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
import chrome from 'ui/chrome';
import { PersistedLog } from './';
import { createLogKey } from './create_log_key';
var RecentlyAccessed = /** @class */ (function () {
    function RecentlyAccessed() {
        var logKey = createLogKey('recentlyAccessed', chrome.getBasePath());
        this.history = new PersistedLog(logKey, {
            maxLength: 20,
            filterDuplicates: true,
            isDuplicate: function (oldItem, newItem) {
                return oldItem.id === newItem.id;
            },
        });
    }
    RecentlyAccessed.prototype.add = function (link, label, id) {
        this.history.add({
            link: link,
            label: label,
            id: id,
        });
    };
    RecentlyAccessed.prototype.get = function () {
        return this.history.get();
    };
    return RecentlyAccessed;
}());
export var recentlyAccessed = new RecentlyAccessed();
