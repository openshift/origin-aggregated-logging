'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _i18n = require('@kbn/i18n');

var _lodash = require('lodash');

var _lodash2 = _interopRequireDefault(_lodash);

var _datasource = require('../../lib/classes/datasource');

var _datasource2 = _interopRequireDefault(_datasource);

var _build_request = require('./lib/build_request');

var _build_request2 = _interopRequireDefault(_build_request);

var _agg_response_to_series_list = require('./lib/agg_response_to_series_list');

var _agg_response_to_series_list2 = _interopRequireDefault(_agg_response_to_series_list);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.default = new _datasource2.default('es', {
  args: [{
    name: 'q',
    types: ['string', 'null'],
    multi: true,
    help: _i18n.i18n.translate('timelion.help.functions.es.args.qHelpText', {
      defaultMessage: 'Query in lucene query string syntax'
    })
  }, {
    name: 'metric',
    types: ['string', 'null'],
    multi: true,
    help: _i18n.i18n.translate('timelion.help.functions.es.args.metricHelpText', {
      defaultMessage: 'An elasticsearch metric agg: avg, sum, min, max, percentiles or cardinality, followed by a field. ' + 'E.g., "sum:bytes", "percentiles:bytes:95,99,99.9" or just "count"',
      description: `avg, sum, min, max, percentiles and cardinality are keywords in the expression ` + `and must not be translated. Also don't translate the examples.`
    })
  }, {
    name: 'split',
    types: ['string', 'null'],
    multi: true,
    help: _i18n.i18n.translate('timelion.help.functions.es.args.splitHelpText', {
      defaultMessage: 'An elasticsearch field to split the series on and a limit. E.g., "{hostnameSplitArg}" to get the top 10 hostnames',
      values: {
        hostnameSplitArg: 'hostname:10'
      }
    })
  }, {
    name: 'index',
    types: ['string', 'null'],
    help: _i18n.i18n.translate('timelion.help.functions.es.args.indexHelpText', {
      defaultMessage: 'Index to query, wildcards accepted. Provide Index Pattern name for scripted fields and ' + 'field name type ahead suggestions for metrics, split, and timefield arguments.',
      description: '"metrics", "split" and "timefield" are referring to parameter names and should not be translated.'
    })
  }, {
    name: 'timefield',
    types: ['string', 'null'],
    help: _i18n.i18n.translate('timelion.help.functions.es.args.timefieldHelpText', {
      defaultMessage: 'Field of type "date" to use for x-axis',
      description: '"date" is a field type and should not be translated.'
    })
  }, {
    name: 'kibana',
    types: ['boolean', 'null'],
    help: _i18n.i18n.translate('timelion.help.functions.es.args.kibanaHelpText', {
      defaultMessage: 'Respect filters on Kibana dashboards. Only has an effect when using on Kibana dashboards'
    })
  }, {
    name: 'interval', // You really shouldn't use this, use the interval picker instead
    types: ['string', 'null'],
    help: _i18n.i18n.translate('timelion.help.functions.es.args.intervalHelpText', {
      defaultMessage: `**DO NOT USE THIS**. It's fun for debugging fit functions, but you really should use the interval picker`
    })
  }],
  help: _i18n.i18n.translate('timelion.help.functions.esHelpText', {
    defaultMessage: 'Pull data from an elasticsearch instance'
  }),
  aliases: ['elasticsearch'],
  fn: async function esFn(args, tlConfig) {

    const config = _lodash2.default.defaults(_lodash2.default.clone(args.byName), {
      q: '*',
      metric: ['count'],
      index: tlConfig.settings['timelion:es.default_index'],
      timefield: tlConfig.settings['timelion:es.timefield'],
      interval: tlConfig.time.interval,
      kibana: true,
      fit: 'nearest'
    });

    const findResp = await tlConfig.request.getSavedObjectsClient().find({
      type: 'index-pattern',
      fields: ['title', 'fields'],
      search: `"${config.index}"`,
      search_fields: ['title']
    });
    const indexPatternSavedObject = findResp.saved_objects.find(savedObject => {
      return savedObject.attributes.title === config.index;
    });
    let scriptedFields = [];
    if (indexPatternSavedObject) {
      const fields = JSON.parse(indexPatternSavedObject.attributes.fields);
      scriptedFields = fields.filter(field => {
        return field.scripted;
      });
    }

    const body = (0, _build_request2.default)(config, tlConfig, scriptedFields);

    const { callWithRequest } = tlConfig.server.plugins.elasticsearch.getCluster('data');
    const resp = await callWithRequest(tlConfig.request, 'search', body);
    if (!resp._shards.total) {
      throw new Error(_i18n.i18n.translate('timelion.serverSideErrors.esFunction.indexNotFoundErrorMessage', {
        defaultMessage: 'Elasticsearch index not found: {index}',
        values: {
          index: config.index
        }
      }));
    }
    return {
      type: 'seriesList',
      list: (0, _agg_response_to_series_list2.default)(resp.aggregations, config)
    };
  }
}); /*
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

module.exports = exports['default'];