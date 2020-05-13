'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

exports.default = function (api) {

  // Note: this isn't an actual API endpoint. It exists so the forEach processor's "processor" field
  // may recursively use the autocomplete rules for any processor.
  api.addEndpointDescription('_processor', {
    data_autocomplete_rules: processorDefinition
  });

  api.addEndpointDescription('ingest.put_pipeline', {
    methods: ['PUT'],
    patterns: ['_ingest/pipeline/{id}'],
    data_autocomplete_rules: pipelineDefinition
  });

  api.addEndpointDescription('ingest.simulate', {
    data_autocomplete_rules: {
      pipeline: pipelineDefinition,
      docs: []
    }
  });
};

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

const commonPipelineParams = {
  on_failure: [],
  ignore_failure: {
    __one_of: [false, true]
  },
  if: '',
  tag: ''
};

// Based on https://www.elastic.co/guide/en/elasticsearch/reference/master/append-processor.html
const appendProcessorDefinition = {
  append: _extends({
    __template: {
      field: '',
      value: []
    },
    field: '',
    value: []
  }, commonPipelineParams)
};

// Based on https://www.elastic.co/guide/en/elasticsearch/reference/master/bytes-processor.html
const bytesProcessorDefinition = {
  bytes: _extends({
    __template: {
      field: ''
    },
    field: '',
    target_field: '',
    ignore_missing: {
      __one_of: [false, true]
    }
  }, commonPipelineParams)
};

// Based on https://www.elastic.co/guide/en/elasticsearch/reference/master/convert-processor.html
const convertProcessorDefinition = {
  convert: _extends({
    __template: {
      field: '',
      type: ''
    },
    field: '',
    type: {
      __one_of: ['integer', 'float', 'string', 'boolean', 'auto']
    },
    target_field: '',
    ignore_missing: {
      __one_of: [false, true]
    }
  }, commonPipelineParams)
};

// Based on https://www.elastic.co/guide/en/elasticsearch/reference/master/date-processor.html
const dateProcessorDefinition = {
  date: _extends({
    __template: {
      field: '',
      formats: []
    },
    field: '',
    target_field: '@timestamp',
    formats: [],
    timezone: 'UTC',
    locale: 'ENGLISH'
  }, commonPipelineParams)
};

// Based on https://www.elastic.co/guide/en/elasticsearch/reference/master/date-index-name-processor.html
const dateIndexNameProcessorDefinition = {
  date_index_name: _extends({
    __template: {
      field: '',
      date_rounding: ''
    },
    field: '',
    date_rounding: {
      __one_of: ['y', 'M', 'w', 'd', 'h', 'm', 's']
    },
    date_formats: [],
    timezone: 'UTC',
    locale: 'ENGLISH',
    index_name_format: 'yyyy-MM-dd'
  }, commonPipelineParams)
};

// Based on https://www.elastic.co/guide/en/elasticsearch/reference/master/dissect-processor.html
const dissectProcessorDefinition = {
  dissect: _extends({
    __template: {
      field: '',
      pattern: ''
    },
    field: '',
    pattern: '',
    append_separator: '',
    ignore_missing: {
      __one_of: [false, true]
    }
  }, commonPipelineParams)
};

// Based on https://www.elastic.co/guide/en/elasticsearch/reference/master/dot-expand-processor.html
const dotExpanderProcessorDefinition = {
  dot_expander: _extends({
    __template: {
      field: ''
    },
    field: '',
    path: ''
  }, commonPipelineParams)
};

// Based on https://www.elastic.co/guide/en/elasticsearch/reference/master/drop-processor.html
const dropProcessorDefinition = {
  drop: _extends({
    __template: {}
  }, commonPipelineParams)
};

// Based on https://www.elastic.co/guide/en/elasticsearch/reference/master/fail-processor.html
const failProcessorDefinition = {
  fail: _extends({
    __template: {
      message: ''
    },
    message: ''
  }, commonPipelineParams)
};

// Based on https://www.elastic.co/guide/en/elasticsearch/reference/master/foreach-processor.html
const foreachProcessorDefinition = {
  foreach: _extends({
    __template: {
      field: '',
      processor: {}
    },
    field: '',
    processor: {
      __scope_link: '_processor'
    }
  }, commonPipelineParams)
};

// Based on https://www.elastic.co/guide/en/elasticsearch/reference/master/grok-processor.html
const grokProcessorDefinition = {
  grok: _extends({
    __template: {
      field: '',
      patterns: []
    },
    field: '',
    patterns: [],
    pattern_definitions: {},
    trace_match: {
      __one_of: [false, true]
    },
    ignore_missing: {
      __one_of: [false, true]
    }
  }, commonPipelineParams)
};

// Based on https://www.elastic.co/guide/en/elasticsearch/reference/master/gsub-processor.html
const gsubProcessorDefinition = {
  gsub: _extends({
    __template: {
      field: '',
      pattern: '',
      replacement: ''
    },
    field: '',
    pattern: '',
    replacement: ''
  }, commonPipelineParams)
};

// Based on https://www.elastic.co/guide/en/elasticsearch/reference/master/join-processor.html
const joinProcessorDefinition = {
  join: _extends({
    __template: {
      field: '',
      separator: ''
    },
    field: '',
    separator: ''
  }, commonPipelineParams)
};

// Based on https://www.elastic.co/guide/en/elasticsearch/reference/master/json-processor.html
const jsonProcessorDefinition = {
  json: _extends({
    __template: {
      field: ''
    },
    field: '',
    target_field: '',
    add_to_root: {
      __one_of: [false, true]
    }
  }, commonPipelineParams)
};

// Based on https://www.elastic.co/guide/en/elasticsearch/reference/master/kv-processor.html
const kvProcessorDefinition = {
  kv: _extends({
    __template: {
      field: '',
      field_split: '',
      value_split: ''
    },
    field: '',
    field_split: '',
    value_split: '',
    target_field: '',
    include_keys: [],
    ignore_missing: {
      __one_of: [false, true]
    }
  }, commonPipelineParams)
};

// Based on https://www.elastic.co/guide/en/elasticsearch/reference/master/lowercase-processor.html
const lowercaseProcessorDefinition = {
  lowercase: _extends({
    __template: {
      field: ''
    },
    field: '',
    ignore_missing: {
      __one_of: [false, true]
    }
  }, commonPipelineParams)
};

// Based on https://www.elastic.co/guide/en/elasticsearch/reference/master/pipeline-processor.html
const pipelineProcessorDefinition = {
  pipeline: _extends({
    __template: {
      name: ''
    },
    name: ''
  }, commonPipelineParams)
};

// Based on https://www.elastic.co/guide/en/elasticsearch/reference/master/remove-processor.html
const removeProcessorDefinition = {
  remove: _extends({
    __template: {
      field: ''
    },
    field: ''
  }, commonPipelineParams)
};

// Based on https://www.elastic.co/guide/en/elasticsearch/reference/master/rename-processor.html
const renameProcessorDefinition = {
  rename: _extends({
    __template: {
      field: '',
      target_field: ''
    },
    field: '',
    target_field: '',
    ignore_missing: {
      __one_of: [false, true]
    }
  }, commonPipelineParams)
};

// Based on https://www.elastic.co/guide/en/elasticsearch/reference/master/script-processor.html
const scriptProcessorDefinition = {
  script: _extends({
    __template: {},
    lang: 'painless',
    file: '',
    id: '',
    source: '',
    params: {}
  }, commonPipelineParams)
};

// Based on https://www.elastic.co/guide/en/elasticsearch/reference/master/set-processor.html
const setProcessorDefinition = {
  set: _extends({
    __template: {
      field: '',
      value: ''
    },
    field: '',
    value: '',
    override: {
      __one_of: [true, false]
    }
  }, commonPipelineParams)
};

// Based on https://www.elastic.co/guide/en/elasticsearch/reference/master/split-processor.html
const splitProcessorDefinition = {
  split: _extends({
    __template: {
      field: '',
      separator: ''
    },
    field: '',
    separator: '',
    ignore_missing: {
      __one_of: [false, true]
    }
  }, commonPipelineParams)
};

// Based on https://www.elastic.co/guide/en/elasticsearch/reference/master/sort-processor.html
const sortProcessorDefinition = {
  sort: _extends({
    __template: {
      field: ''
    },
    field: '',
    order: 'asc'
  }, commonPipelineParams)
};

// Based on https://www.elastic.co/guide/en/elasticsearch/reference/master/trim-processor.html
const trimProcessorDefinition = {
  trim: _extends({
    __template: {
      field: ''
    },
    field: '',
    ignore_missing: {
      __one_of: [false, true]
    }
  }, commonPipelineParams)
};

// Based on https://www.elastic.co/guide/en/elasticsearch/reference/master/uppercase-processor.html
const uppercaseProcessorDefinition = {
  uppercase: _extends({
    __template: {
      field: ''
    },
    field: '',
    ignore_missing: {
      __one_of: [false, true]
    }
  }, commonPipelineParams)
};

const processorDefinition = {
  __one_of: [appendProcessorDefinition, bytesProcessorDefinition, convertProcessorDefinition, dateProcessorDefinition, dateIndexNameProcessorDefinition, dissectProcessorDefinition, dotExpanderProcessorDefinition, dropProcessorDefinition, failProcessorDefinition, foreachProcessorDefinition, grokProcessorDefinition, gsubProcessorDefinition, joinProcessorDefinition, jsonProcessorDefinition, kvProcessorDefinition, lowercaseProcessorDefinition, pipelineProcessorDefinition, removeProcessorDefinition, renameProcessorDefinition, scriptProcessorDefinition, setProcessorDefinition, splitProcessorDefinition, sortProcessorDefinition, trimProcessorDefinition, uppercaseProcessorDefinition]
};

const pipelineDefinition = {
  description: '',
  processors: [processorDefinition],
  version: 123
};

module.exports = exports['default'];