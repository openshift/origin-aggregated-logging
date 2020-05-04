'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.kafkaLogsSpecProvider = kafkaLogsSpecProvider;

var _i18n = require('@kbn/i18n');

var _tutorial_category = require('../../../common/tutorials/tutorial_category');

var _filebeat_instructions = require('../../../common/tutorials/filebeat_instructions');

function kafkaLogsSpecProvider(server, context) {
  const moduleName = 'kafka';
  const platforms = ['OSX', 'DEB', 'RPM', 'WINDOWS'];
  return {
    id: 'kafkaLogs',
    name: _i18n.i18n.translate('kbn.server.tutorials.kafkaLogs.nameTitle', {
      defaultMessage: 'Kafka logs'
    }),
    category: _tutorial_category.TUTORIAL_CATEGORY.LOGGING,
    shortDescription: _i18n.i18n.translate('kbn.server.tutorials.kafkaLogs.shortDescription', {
      defaultMessage: 'Collect and parse logs created by Kafka.'
    }),
    longDescription: _i18n.i18n.translate('kbn.server.tutorials.kafkaLogs.longDescription', {
      defaultMessage: 'The `kafka` Filebeat module parses logs created by Kafka. \
[Learn more]({learnMoreLink}).',
      values: {
        learnMoreLink: '{config.docs.beats.filebeat}/filebeat-module-kafka.html'
      }
    }),
    euiIconType: 'logoKafka',
    artifacts: {
      dashboards: [{
        id: '943caca0-87ee-11e7-ad9c-db80de0bf8d3',
        linkLabel: _i18n.i18n.translate('kbn.server.tutorials.kafkaLogs.artifacts.dashboards.linkLabel', {
          defaultMessage: 'Kafka logs dashboard'
        }),
        isOverview: true
      }],
      exportedFields: {
        documentationUrl: '{config.docs.beats.filebeat}/exported-fields-kafka.html'
      }
    },
    completionTimeMinutes: 10,
    previewImagePath: '/plugins/kibana/home/tutorial_resources/kafka_logs/screenshot.png',
    onPrem: (0, _filebeat_instructions.onPremInstructions)(moduleName, platforms, context),
    elasticCloud: (0, _filebeat_instructions.cloudInstructions)(moduleName, platforms),
    onPremElasticCloud: (0, _filebeat_instructions.onPremCloudInstructions)(moduleName, platforms)
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