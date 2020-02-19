'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.uwsgiMetricsSpecProvider = uwsgiMetricsSpecProvider;

var _i18n = require('@kbn/i18n');

var _tutorial_category = require('../../../common/tutorials/tutorial_category');

var _metricbeat_instructions = require('../../../common/tutorials/metricbeat_instructions');

function uwsgiMetricsSpecProvider(server, context) {
  const moduleName = 'uwsgi';
  return {
    id: 'uwsgiMetrics',
    name: _i18n.i18n.translate('kbn.server.tutorials.uwsgiMetrics.nameTitle', {
      defaultMessage: 'uWSGI metrics'
    }),
    category: _tutorial_category.TUTORIAL_CATEGORY.METRICS,
    shortDescription: _i18n.i18n.translate('kbn.server.tutorials.uwsgiMetrics.shortDescription', {
      defaultMessage: 'Fetch internal metrics from the uWSGI server.'
    }),
    longDescription: _i18n.i18n.translate('kbn.server.tutorials.uwsgiMetrics.longDescription', {
      defaultMessage: 'The `uwsgi` Metricbeat module fetches internal metrics from the uWSGI server. \
[Learn more]({learnMoreLink}).',
      values: {
        learnMoreLink: '{config.docs.beats.metricbeat}/metricbeat-module-uwsgi.html'
      }
    }),
    //euiIconType: 'logouWSGI',
    isBeta: false,
    artifacts: {
      dashboards: [{
        id: '32fca290-f0af-11e7-b9ff-9f96241065de',
        linkLabel: _i18n.i18n.translate('kbn.server.tutorials.uwsgiMetrics.artifacts.dashboards.linkLabel', {
          defaultMessage: 'uWSGI metrics dashboard'
        }),
        isOverview: true
      }],
      exportedFields: {
        documentationUrl: '{config.docs.beats.metricbeat}/exported-fields-uwsgi.html'
      }
    },
    completionTimeMinutes: 10,
    previewImagePath: '/plugins/kibana/home/tutorial_resources/uwsgi_metrics/screenshot.png',
    onPrem: (0, _metricbeat_instructions.onPremInstructions)(moduleName, null, null, null, context),
    elasticCloud: (0, _metricbeat_instructions.cloudInstructions)(moduleName),
    onPremElasticCloud: (0, _metricbeat_instructions.onPremCloudInstructions)(moduleName)
  };
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