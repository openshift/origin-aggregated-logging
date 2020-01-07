'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.PUBLIC_PATH_PLACEHOLDER = undefined;
exports.replacePlaceholder = replacePlaceholder;

var _utils = require('../utils');

var _rxjs = require('rxjs');

var Rx = _interopRequireWildcard(_rxjs);

var _operators = require('rxjs/operators');

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

const PUBLIC_PATH_PLACEHOLDER = exports.PUBLIC_PATH_PLACEHOLDER = '__REPLACE_WITH_PUBLIC_PATH__'; /*
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

function replacePlaceholder(read, replacement) {
  const replace = (0, _utils.createReplaceStream)(PUBLIC_PATH_PLACEHOLDER, replacement);

  // handle errors on the read stream by proxying them
  // to the replace stream so that the consumer can
  // choose what to do with them.
  Rx.fromEvent(read, 'error').pipe((0, _operators.take)(1), (0, _operators.takeUntil)(Rx.fromEvent(read, 'end'))).forEach(error => {
    replace.emit('error', error);
    replace.end();
  });

  replace.close = () => {
    read.unpipe();
    read.close();
  };

  return read.pipe(replace);
}