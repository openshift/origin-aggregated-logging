'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getHighlightHtml = getHighlightHtml;

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _highlight_tags = require('./highlight_tags');

var _html_tags = require('./html_tags');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function getHighlightHtml(fieldValue, highlights) {
  let highlightHtml = typeof fieldValue === 'object' ? JSON.stringify(fieldValue) : fieldValue;

  _lodash2.default.each(highlights, function (highlight) {
    const escapedHighlight = _lodash2.default.escape(highlight);

    // Strip out the highlight tags to compare against the field text
    const untaggedHighlight = escapedHighlight.split(_highlight_tags.highlightTags.pre).join('').split(_highlight_tags.highlightTags.post).join('');

    // Replace all highlight tags with proper html tags
    const taggedHighlight = escapedHighlight.split(_highlight_tags.highlightTags.pre).join(_html_tags.htmlTags.pre).split(_highlight_tags.highlightTags.post).join(_html_tags.htmlTags.post);

    // Replace all instances of the untagged string with the properly tagged string
    highlightHtml = highlightHtml.split(untaggedHighlight).join(taggedHighlight);
  });

  return highlightHtml;
} /*
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