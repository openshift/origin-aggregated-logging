'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.UsageCollector = undefined;

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

var _constants = require('../../status/constants');

var _collector = require('./collector');

function _objectWithoutProperties(obj, keys) { var target = {}; for (var i in obj) { if (keys.indexOf(i) >= 0) continue; if (!Object.prototype.hasOwnProperty.call(obj, i)) continue; target[i] = obj[i]; } return target; } /*
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

class UsageCollector extends _collector.Collector {
  /*
   * @param {Object} server - server object
   * @param {String} options.type - property name as the key for the data
   * @param {Function} options.init (optional) - initialization function
   * @param {Function} options.fetch - function to query data
   * @param {Function} options.formatForBulkUpload - optional
   * @param {Function} options.rest - optional other properties
   */
  constructor(server, _ref = {}) {
    let { type, init, fetch, formatForBulkUpload = null } = _ref,
        options = _objectWithoutProperties(_ref, ['type', 'init', 'fetch', 'formatForBulkUpload']);

    super(server, _extends({ type, init, fetch, formatForBulkUpload }, options));

    /*
     * Currently, for internal bulk uploading, usage stats are part of
     * `kibana_stats` type, under the `usage` namespace in the document.
     */
    const defaultUsageFormatterForBulkUpload = result => {
      return {
        type: _constants.KIBANA_STATS_TYPE,
        payload: {
          usage: {
            [type]: result
          }
        }
      };
    };
    this._formatForBulkUpload = formatForBulkUpload || defaultUsageFormatterForBulkUpload;
  }
}
exports.UsageCollector = UsageCollector;