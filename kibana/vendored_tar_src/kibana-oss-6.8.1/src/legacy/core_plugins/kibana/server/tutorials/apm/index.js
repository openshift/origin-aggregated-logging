'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.apmSpecProvider = apmSpecProvider;

var _i18n = require('@kbn/i18n');

var _tutorial_category = require('../../../common/tutorials/tutorial_category');

var _on_prem = require('./envs/on_prem');

var _elastic_cloud = require('./envs/elastic_cloud');

var _get_saved_objects = require('./saved_objects/get_saved_objects');

const apmIntro = _i18n.i18n.translate('kbn.server.tutorials.apm.introduction', {
  defaultMessage: 'Collect in-depth performance metrics and errors from inside your applications.'
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

function isEnabled(config) {
  const ENABLED_KEY = 'xpack.apm.ui.enabled';
  if (config.has(ENABLED_KEY)) {
    return config.get(ENABLED_KEY);
  }

  return false;
}

function apmSpecProvider(server) {
  const config = server.config();
  const apmIndexPatternTitle = config.get('apm_oss.indexPattern');

  const artifacts = {
    dashboards: [{
      id: '8d3ed660-7828-11e7-8c47-65b845b5cfb3',
      linkLabel: _i18n.i18n.translate('kbn.server.tutorials.apm.specProvider.artifacts.dashboards.linkLabel', {
        defaultMessage: 'APM dashboard'
      }),
      isOverview: true
    }]
  };

  if (isEnabled(config)) {
    artifacts.application = {
      path: '/app/apm',
      label: _i18n.i18n.translate('kbn.server.tutorials.apm.specProvider.artifacts.application.label', {
        defaultMessage: 'Launch APM'
      })
    };
  }

  return {
    id: 'apm',
    name: _i18n.i18n.translate('kbn.server.tutorials.apm.specProvider.name', {
      defaultMessage: 'APM'
    }),
    category: _tutorial_category.TUTORIAL_CATEGORY.OTHER,
    shortDescription: apmIntro,
    longDescription: _i18n.i18n.translate('kbn.server.tutorials.apm.specProvider.longDescription', {
      defaultMessage: 'Application Performance Monitoring (APM) collects in-depth \
performance metrics and errors from inside your application. \
It allows you to monitor the performance of thousands of applications in real time. \
[Learn more]({learnMoreLink}).',
      values: {
        learnMoreLink: '{config.docs.base_url}guide/en/apm/get-started/{config.docs.version}/index.html'
      }
    }),
    euiIconType: 'apmApp',
    artifacts: artifacts,
    onPrem: (0, _on_prem.onPremInstructions)(apmIndexPatternTitle),
    elasticCloud: (0, _elastic_cloud.createElasticCloudInstructions)(config),
    previewImagePath: '/plugins/kibana/home/tutorial_resources/apm/apm.png',
    savedObjects: (0, _get_saved_objects.getSavedObjects)(apmIndexPatternTitle),
    savedObjectsInstallMsg: _i18n.i18n.translate('kbn.server.tutorials.apm.specProvider.savedObjectsInstallMsg', {
      defaultMessage: 'Load index pattern, visualizations, and pre-defined dashboards. \
An index pattern is required for some features in the APM UI.'
    })
  };
}