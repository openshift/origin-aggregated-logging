'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.tutorialSchema = undefined;

var _joi = require('joi');

var _joi2 = _interopRequireDefault(_joi);

var _param_types = require('./param_types');

var _tutorial_category = require('./tutorial_category');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const dashboardSchema = _joi2.default.object({
  id: _joi2.default.string().required(), // Dashboard saved object id
  linkLabel: _joi2.default.string().when('isOverview', {
    is: true,
    then: _joi2.default.required()
  }),
  // Is this an Overview / Entry Point dashboard?
  isOverview: _joi2.default.boolean().required()
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

const artifactsSchema = _joi2.default.object({
  // Fields present in Elasticsearch documents created by this product.
  exportedFields: _joi2.default.object({
    documentationUrl: _joi2.default.string().required()
  }),
  // Kibana dashboards created by this product.
  dashboards: _joi2.default.array().items(dashboardSchema).required(),
  application: _joi2.default.object({
    path: _joi2.default.string().required(),
    label: _joi2.default.string().required()
  })
});

const statusCheckSchema = _joi2.default.object({
  title: _joi2.default.string(),
  text: _joi2.default.string(),
  btnLabel: _joi2.default.string(),
  success: _joi2.default.string(),
  error: _joi2.default.string(),
  esHitsCheck: _joi2.default.object({
    index: _joi2.default.string().required(),
    query: _joi2.default.object().required()
  }).required()
});

const instructionSchema = _joi2.default.object({
  title: _joi2.default.string(),
  textPre: _joi2.default.string(),
  commands: _joi2.default.array().items(_joi2.default.string().allow('')),
  textPost: _joi2.default.string()
});

const instructionVariantSchema = _joi2.default.object({
  id: _joi2.default.string().required(),
  instructions: _joi2.default.array().items(instructionSchema).required()
});

const instructionSetSchema = _joi2.default.object({
  title: _joi2.default.string(),
  // Variants (OSes, languages, etc.) for which tutorial instructions are specified.
  instructionVariants: _joi2.default.array().items(instructionVariantSchema).required(),
  statusCheck: statusCheckSchema
});

const paramSchema = _joi2.default.object({
  defaultValue: _joi2.default.required(),
  id: _joi2.default.string().regex(/^[a-zA-Z_]+$/).required(),
  label: _joi2.default.string().required(),
  type: _joi2.default.string().valid(Object.values(_param_types.PARAM_TYPES)).required()
});

const instructionsSchema = _joi2.default.object({
  instructionSets: _joi2.default.array().items(instructionSetSchema).required(),
  params: _joi2.default.array().items(paramSchema)
});

const tutorialSchema = exports.tutorialSchema = {
  id: _joi2.default.string().regex(/^[a-zA-Z0-9-]+$/).required(),
  category: _joi2.default.string().valid(Object.values(_tutorial_category.TUTORIAL_CATEGORY)).required(),
  name: _joi2.default.string().required(),
  isBeta: _joi2.default.boolean().default(false),
  shortDescription: _joi2.default.string().required(),
  euiIconType: _joi2.default.string(), //EUI icon type string, one of https://elastic.github.io/eui/#/icons
  longDescription: _joi2.default.string().required(),
  completionTimeMinutes: _joi2.default.number().integer(),
  previewImagePath: _joi2.default.string(),

  // kibana and elastic cluster running on prem
  onPrem: instructionsSchema.required(),

  // kibana and elastic cluster running in elastic's cloud
  elasticCloud: instructionsSchema,

  // kibana running on prem and elastic cluster running in elastic's cloud
  onPremElasticCloud: instructionsSchema,

  // Elastic stack artifacts produced by product when it is setup and run.
  artifacts: artifactsSchema,

  // saved objects used by data module.
  savedObjects: _joi2.default.array().items(),
  savedObjectsInstallMsg: _joi2.default.string()
};