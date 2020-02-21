'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.WildcardMatcher = undefined;

var _minimatch = require('minimatch');

class WildcardMatcher {
  constructor(wildcardPattern, emptyVal) {
    this.emptyVal = emptyVal;
    this.pattern = String(wildcardPattern || '*');
    this.matcher = new _minimatch.Minimatch(this.pattern, {
      noglobstar: true,
      dot: true,
      nocase: true,
      matchBase: true,
      nocomment: true
    });
  }

  match(candidate) {
    const empty = !candidate || candidate === this.emptyVal;
    if (empty && this.pattern === '*') {
      return true;
    }

    return this.matcher.match(candidate || '');
  }
}
exports.WildcardMatcher = WildcardMatcher; /*
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