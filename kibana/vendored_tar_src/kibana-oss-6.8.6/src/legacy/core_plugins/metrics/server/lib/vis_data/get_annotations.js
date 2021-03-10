'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _build_annotation_request = require('./build_annotation_request');

var _build_annotation_request2 = _interopRequireDefault(_build_annotation_request);

var _handle_annotation_response = require('./handle_annotation_response');

var _handle_annotation_response2 = _interopRequireDefault(_handle_annotation_response);

var _get_index_pattern = require('./helpers/get_index_pattern');

var _get_es_shard_timeout = require('./helpers/get_es_shard_timeout');

var _get_es_shard_timeout2 = _interopRequireDefault(_get_es_shard_timeout);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

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

function validAnnotation(annotation) {
  return annotation.index_pattern && annotation.time_field && annotation.fields && annotation.icon && annotation.template;
}

exports.default = async (req, panel, esQueryConfig) => {
  const { callWithRequest } = req.server.plugins.elasticsearch.getCluster('data');
  const bodiesPromises = panel.annotations.filter(validAnnotation).map(annotation => {
    return getAnnotationBody(req, panel, annotation, esQueryConfig);
  });
  const bodies = await Promise.all(bodiesPromises);
  if (!bodies.length) {
    return {
      responses: []
    };
  }
  try {
    const includeFrozen = await req.getUiSettingsService().get('search:includeFrozen');
    const resp = await callWithRequest(req, 'msearch', {
      ignore_throttled: !includeFrozen,
      rest_total_hits_as_int: true,
      body: bodies.reduce((acc, item) => acc.concat(item), [])
    });
    const results = {};
    panel.annotations.filter(validAnnotation).forEach((annotation, index) => {
      const data = resp.responses[index];
      results[annotation.id] = (0, _handle_annotation_response2.default)(data, annotation);
    });
    return results;
  } catch (error) {
    if (error.message === 'missing-indices') return { responses: [] };
    throw error;
  }
};

async function getAnnotationBody(req, panel, annotation, esQueryConfig) {
  const indexPattern = annotation.index_pattern;
  const { indexPatternObject, indexPatternString } = await (0, _get_index_pattern.getIndexPatternObject)(req, indexPattern);
  const request = (0, _build_annotation_request2.default)(req, panel, annotation, esQueryConfig, indexPatternObject);
  const esShardTimeout = (0, _get_es_shard_timeout2.default)(req);

  if (esShardTimeout > 0) {
    request.timeout = `${esShardTimeout}ms`;
  }

  return [{
    index: indexPatternString,
    ignoreUnavailable: true
  }, request];
}
module.exports = exports['default'];