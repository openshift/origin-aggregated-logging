'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createSourceFormat = createSourceFormat;

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _no_white_space = require('../../utils/no_white_space');

var _shorten_dotted_string = require('../../utils/shorten_dotted_string');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const templateHtml = `
  <dl class="source truncate-by-height">
    <% defPairs.forEach(function (def) { %>
      <dt><%- def[0] %>:</dt>
      <dd><%= def[1] %></dd>
      <%= ' ' %>
    <% }); %>
  </dl>`; /*
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

const template = _lodash2.default.template((0, _no_white_space.noWhiteSpace)(templateHtml));

function createSourceFormat(FieldFormat) {
  class SourceFormat extends FieldFormat {
    constructor(params, getConfig) {
      super(params);

      this.getConfig = getConfig;
    }

  }

  SourceFormat.id = '_source';
  SourceFormat.title = '_source';
  SourceFormat.fieldType = '_source';
  SourceFormat.prototype._convert = {
    text: value => JSON.stringify(value),
    html: function sourceToHtml(source, field, hit) {
      if (!field) return _lodash2.default.escape(this.getConverterFor('text')(source));

      const highlights = hit && hit.highlight || {};
      const formatted = field.indexPattern.formatHit(hit);
      const highlightPairs = [];
      const sourcePairs = [];

      const isShortDots = this.getConfig('shortDots:enable');
      _lodash2.default.keys(formatted).forEach(key => {
        const pairs = highlights[key] ? highlightPairs : sourcePairs;
        const field = isShortDots ? (0, _shorten_dotted_string.shortenDottedString)(key) : key;
        const val = formatted[key];
        pairs.push([field, val]);
      }, []);

      return template({ defPairs: highlightPairs.concat(sourcePairs) });
    }
  };

  return SourceFormat;
}